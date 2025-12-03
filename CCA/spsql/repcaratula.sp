/******************************************************************/
/*  Archivo:            repcaratula.sp                            */
/*  Stored procedure:   sp_reporte_caratula_cred                  */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 12-Ago-2019                               */
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
/*   - Envia a aplicar las ordenes de pago de las operaciones     */
/*     hijas                                                      */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR           RAZON                      */
/*  12/Ago/19        Lorena Regalado   Genera Caratula de         */
/*                                     Credito                    */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_reporte_caratula_cred') IS NOT NULL
	DROP PROCEDURE dbo.sp_reporte_caratula_cred
GO

create proc sp_reporte_caratula_cred
   @t_trn              int          = 77526,
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(15),
   @i_nemonico         varchar(10)
 
as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(255),
   @w_rol_act              varchar(10),
   @w_oficial              smallint,
   @w_plazo_op             smallint,
   @w_plazo                smallint,
   @w_tipo_seguro          varchar(10), 
   @w_monto_seguro         money, 
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_operacion            int,
   @w_cotizacion_hoy       money,
   @w_rowcount		   int,
   @w_moneda_nacional      tinyint,
   @w_num_dec              tinyint,
   @w_ssn                  int,
   @w_op_forma_pago        catalogo,
   @w_secuencial           int,
   @w_return               int,
   @w_commit               char(1),
   @w_monto_desembolso     money,
   @w_tipo_orden           catalogo,
   @w_banco                catalogo,
   @w_grupo                int,
   @w_fecha_ing            datetime,
   @w_tasa_anual_fija      varchar(10),
   @w_tasa_int             float,
   @w_nemonico_int         catalogo,
   @w_simbolo              varchar(10),
   @w_monto_moneda         varchar(20),
   @w_sucursal             varchar(30),
   @w_fecha_ini            datetime,
   @w_moneda               tinyint,
   @w_ciclo                smallint,
   @w_monto_pagar          money,
   @w_nombre_grupo         varchar(30),
   @w_monto_pagar_moneda   varchar(30),
   @w_nro_cuenta           cuenta,
   @w_nro_credito          cuenta,
   @w_frecuencia           catalogo,
   @w_periodicidad_pago    varchar(30),
   @w_nemonico_cap         catalogo,
   @w_nemonico_ivaint      catalogo,
   @w_plazo_frecuencia     varchar(30),
   @w_promotor             varchar(30),
   @w_reca                 varchar(30),
   @w_tipo_operacion       catalogo,
   @w_tipo_tramite         catalogo,
   @w_desc_frecuencia      varchar(30),
   @w_nemonico_comdes      catalogo,
   @w_nemonico_ivacod      catalogo,
   @w_desc_topera          varchar(30),
   @w_cat                  float,
   @w_cat_I                float,
   @w_cat_desc             varchar(30),
   @w_fecha_fin            datetime,
   @w_fecha_corte          datetime,
   @w_tipo_grupal          char(1),
   @w_desc_topera_I        varchar(30),
   @w_cat_desc_I           varchar(30),
   @w_tasa_int_I           float,
   @w_monto_I              money,
   @w_monto_pagar_I        money,
   @w_plazo_frecuencia_I   varchar(30),
   @w_fecha_fin_I          datetime,
   @w_fecha_corte_I        datetime,
   @w_oper_padre           cuenta,
   @w_tipo_operacion_I     catalogo,
   @w_plazo_I              smallint,
   @w_frecuencia_I         catalogo,
   @w_seg_opcional         varchar(10),
   @w_seg_obligatorio      varchar(10),
   @w_seg_opcional_I       varchar(10),
   @w_seg_obligatorio_I    varchar(10),
   @w_desc_frecuencia_I    varchar(30)


select @w_cat_I = 0,
       @w_cat   = 0 


--OBTIENE NEMONICO DEL INT
select @w_nemonico_int = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end




if @i_banco is not NULL
begin
    if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @i_banco
                    and op_admin_individual = 'N'
		    and op_estado not in (0,99,3,6))
    begin
       select @w_error = 70203
       goto   ERROR
    end
end


select @w_banco = @i_banco


/* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
exec @w_error = sp_tipo_operacion
     @i_banco  = @i_banco,
     @o_tipo   = @w_tipo_grupal out

if @w_error <> 0 goto ERROR

--print 'Tipo: ' + @w_tipo_grupal

if @w_tipo_grupal = 'I'
begin


   --Consulta operacion grupal relacionada al interciclo
   select @w_oper_padre = dc_referencia_grupal 
   from cob_cartera..ca_det_ciclo, ca_operacion 
   where  dc_tciclo = 'I'
    and   dc_operacion = op_operacion
    and   op_grupal = 'N'
    and   op_banco = @i_banco

    select @w_banco = @w_oper_padre

--print 'entro a obtener la op padre ' + @w_banco 
end

select  @w_tipo_operacion = isnull(op_toperacion, 'NA'),
        @w_desc_topera    = (select y.valor from cobis..cl_tabla z, cobis..cl_catalogo y
                                where z.tabla =  'ca_toperacion'
                                 and   z.codigo = y.tabla 
                                 and   y.codigo = x.op_toperacion),
        @w_cat          = isnull(op_valor_cat,0.0),
        @w_tasa_int     =  (select isnull(ro_porcentaje, 0) from cob_cartera..ca_rubro_op
                                 where  ro_operacion = x.op_operacion
                                 and   ro_concepto  = @w_nemonico_int),
        @w_monto        = isnull(op_monto,0),
        @w_monto_pagar  = isnull((select sum(am_cuota + am_gracia - am_pagado) from cob_cartera..ca_amortizacion
                              where am_operacion = x.op_operacion), 0),

        @w_plazo        = isnull(op_plazo, 0),
        @w_frecuencia   = isnull(op_tdividendo,'NA'),
        @w_fecha_fin    = op_fecha_fin,
        @w_tipo_tramite   = isnull((select tr_tipo from cob_credito..cr_tramite where tr_tramite = x.op_tramite), 'NA'),
        @w_moneda         = op_moneda           
from cob_cartera..ca_operacion x
where op_banco = @w_banco


--Obtener la Descripcion de la Frecuencia
if @w_plazo = 1
begin
        execute sp_desc_frecuencia
        @i_tipo          =    'S',
        @i_tdividendo    =    @w_frecuencia,
        @o_frecuencia    =    @w_desc_frecuencia out
 
end
else
begin
        execute sp_desc_frecuencia
        @i_tipo          =    'P',
        @i_tdividendo    =    @w_frecuencia,
        @o_frecuencia    =    @w_desc_frecuencia out
 
end


select @w_cat          = isnull(@w_cat,0)

if @w_cat = 0
   select @w_cat_desc           = '0.0' + ' ' +  '%' + 'SIN IVA'
else
   select @w_cat_desc           = cast(@w_cat as varchar) + ' ' +  '%' + 'SIN IVA'


select @w_plazo_frecuencia   = cast(@w_plazo as varchar) + ' ' + @w_desc_frecuencia
select @w_fecha_corte        = @s_date

select @w_simbolo = mo_simbolo 
from cobis..cl_moneda
where mo_moneda = @w_moneda


--SEGUROS
if exists (select 1 from cob_cartera..ca_seguros_op, ca_operacion
           where op_banco = @w_banco
            and   op_operacion   = so_oper_padre
            and   so_tipo_seguro = 'B')

   select @w_seg_obligatorio = 'TRUE'


if exists (select 1 from cob_cartera..ca_seguros_op, ca_operacion
           where op_banco = @w_banco
            and   op_operacion   = so_oper_padre
            and   so_tipo_seguro <> 'B')

   select @w_seg_opcional = 'TRUE'


if @w_tipo_grupal = 'I'   --Operacion Ingresada es de Interciclo
begin

select  @w_tipo_operacion_I = isnull(op_toperacion, 'NA'),
        @w_desc_topera_I    = (select y.valor from cobis..cl_tabla z, cobis..cl_catalogo y
                                where z.tabla =  'ca_toperacion'
                                 and   z.codigo = y.tabla 
                                 and   y.codigo = x.op_toperacion),
        @w_cat_I          = isnull(op_valor_cat,0.0),
        @w_tasa_int_I     =  (select isnull(ro_porcentaje, 0) from cob_cartera..ca_rubro_op
                                 where  ro_operacion = x.op_operacion
                                 and   ro_concepto  = @w_nemonico_int),
        @w_monto_I        = isnull(op_monto,0),
        @w_monto_pagar_I  = isnull((select sum(am_cuota + am_gracia - am_pagado) from cob_cartera..ca_amortizacion
                              where am_operacion = x.op_operacion), 0),

        @w_plazo_I        = isnull(op_plazo, 0),
        @w_frecuencia_I   = isnull(op_tdividendo,'NA'),
        @w_fecha_fin_I    = op_fecha_fin
from cob_cartera..ca_operacion x
where op_banco = @i_banco

--Obtener la Descripcion de la Frecuencia
if @w_plazo_I = 1
begin
        execute sp_desc_frecuencia
        @i_tipo          =    'S',
        @i_tdividendo    =    @w_frecuencia_I,
        @o_frecuencia    =    @w_desc_frecuencia_I out
 
end
else
begin
        execute sp_desc_frecuencia
        @i_tipo          =    'P',
        @i_tdividendo    =    @w_frecuencia_I,
        @o_frecuencia    =    @w_desc_frecuencia_I out
 
end



--SEGUROS
if exists (select 1 from cob_cartera..ca_seguros_op, ca_operacion
           where op_banco = @i_banco
            and   op_operacion   = so_oper_padre
            and   so_tipo_seguro = 'B')

   select @w_seg_obligatorio = 'TRUE'
else
   select @w_seg_obligatorio = ' '


if exists (select 1 from cob_cartera..ca_seguros_op, ca_operacion
           where op_banco = @i_banco
            and   op_operacion   = so_oper_padre
            and   so_tipo_seguro <> 'B')

   select @w_seg_opcional = 'TRUE'
else
   select @w_seg_opcional = ' '


  
select @w_plazo_frecuencia_I   = cast(@w_plazo_I as varchar) + ' ' + @w_desc_frecuencia_I
select @w_fecha_corte_I        = @s_date


end

select @w_cat_I  = isnull(@w_cat_I,0)

if @w_cat_I = 0
   select @w_cat_desc_I           = '0.0' + ' ' +  '%' + 'SIN IVA'
else
   select @w_cat_desc_I           = cast(@w_cat_I as varchar) + ' ' +  '%' + 'SIN IVA'


--print 'TipoOperacion ' + @w_tipo_operacion
--print 'MOneda ' + cast(@w_moneda as varchar)
--print 'Nemonico ' + @i_nemonico
--print 'TipoTramite ' + @w_tipo_tramite

--Obtiene el RECA del documento
select @w_reca = id_dato 
from cob_credito..cr_imp_documento
where id_toperacion = @w_tipo_operacion
and   id_moneda     = @w_moneda
and   id_mnemonico  = @i_nemonico
and   id_tipo_tramite = @w_tipo_tramite 


--DEVUELVE LOS VALORES AL FE

--Datos de la Operacion Grupal
    select isnull(@w_desc_topera,' ') as 'TipoCredito',
           @w_cat_desc   as 'Cat',
           isnull(@w_tasa_int,0)      as 'TasaInteres',
           isnull(@w_monto,0)         as 'MontoCredito',
           isnull(@w_monto_pagar,0)   as 'TotalAPagar',
           isnull(@w_plazo_frecuencia, ' ') as 'PlazoCredito',
           isnull(convert(varchar(10),@w_fecha_fin,103), ' ')    as 'FechaLimite',
           isnull(convert(varchar(10),@w_fecha_corte, 103), ' ') as 'FechaCorte',
           isnull(@w_seg_opcional, ' ') as 'FlagSeguroOpcional',
           isnull(@w_seg_obligatorio,' ') as 'FlagSeguroOblig',
           isnull(@w_reca, ' ')           as 'Reca',
     --Datos de la operacion Interciclo
            isnull(@w_desc_topera_I,' ')      as 'TipoCreditoInterc',
            @w_cat_desc_I                     as 'CatInterc',
            isnull(@w_tasa_int_I,0)           as 'TasaInteresInterc',
            isnull(@w_monto_I,0)              as 'MontoCreditoInterc',
            isnull(@w_monto_pagar_I,0)        as 'TotalAPagarInterc',
            isnull(@w_plazo_frecuencia_I,' ') as 'PlazoCreditoInterc',
            isnull(convert(varchar(10),@w_fecha_fin_I,103), ' ')   as 'FechaLimiteInterc',
            isnull(convert(varchar(10), @w_fecha_corte_I,103),' ') as 'FechaCorteInterc',
            isnull(@w_seg_opcional_I, ' ') as 'FlagSeguroOpcionalInterc',
            isnull(@w_seg_obligatorio_I,' ') as 'FlagSeguroObligInterc',
            isnull(@w_simbolo, ' ') as 'SimboloMoneda'




return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = @w_mensaje,
    @i_sev    = 0
   
     return @w_error
  

GO

