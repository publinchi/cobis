/******************************************************************/
/*  Archivo:            reptabla.sp                               */
/*  Stored procedure:   sp_reporte_tabla                          */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 15-Jul-2019                               */
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
/*  15/Jul/19        Lorena Regalado   Genera informacion         */
/*                                     para Tabla amortizacion    */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_reporte_tabla') IS NOT NULL
	DROP PROCEDURE dbo.sp_reporte_tabla
GO

create proc sp_reporte_tabla
   @t_trn              int          = 77510,
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
   @i_tipo             char(1),            --'C'(Cabecera), 'D'(Detalle)
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
   @w_nemonico_ivacod      catalogo




--OBTIENE NEMONICO DEL INT
select @w_nemonico_int = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL CAP
select @w_nemonico_cap = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CAP'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL IVAINT
select @w_nemonico_ivaint = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVAINT'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end



--OBTIENE NEMONICO DEL COMDES
select @w_nemonico_comdes = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMDES'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL IVACOMDES
select @w_nemonico_ivacod = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVACOD'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end



-----------------------------------------------------------
--Operacion para devolver datos de la cabecera del reporte
-----------------------------------------------------------

if @i_tipo = 'C'    --Cabecera de la Tabla de amortizacion
begin


   select @w_sucursal     = (select of_nombre from cobis..cl_oficina
                              where of_oficina = x.op_oficina),
           @w_grupo        = isnull(op_grupo, 0),
           @w_ciclo        = isnull((select case 
                                            when x.op_grupal = 'S' and x.op_ref_grupal is NULL   --Operacion Grupal Padre
                                            then (select max(ci_ciclo) from cob_cartera..ca_ciclo where ci_operacion = x.op_operacion and ci_grupo = x.op_grupo)

                                            when x.op_grupal = 'S' and x.op_ref_grupal is not NULL  --Operaciones Hijas/Interciclo
                                            then (select max(dc_ciclo_grupo) from cob_cartera..ca_det_ciclo
                                                  where  dc_grupo = x.op_grupo and dc_operacion  = x.op_operacion)
                                            when x.op_grupal = 'N' and x.op_ref_grupal is NULL      --Operaciones Individuales
                                            then 0
                               else 0
                               end),0),
           @w_nombre_grupo = isnull((select gr_nombre 
                              from cobis..cl_grupo
                              where gr_grupo  = x.op_grupo), 'NA'),
           @w_nro_cuenta   = isnull(op_cuenta, 'NA'),
           @w_nro_credito  = isnull(op_banco,'NA'),
           @w_monto        = isnull(op_monto,0),
           @w_monto_pagar  = isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                              where am_operacion = x.op_operacion), 0),
           @w_plazo        = isnull(op_plazo, 0),
           @w_frecuencia   = isnull(op_tdividendo,'NA'),
           @w_tasa_int     =  (select isnull(ro_porcentaje, 0) from cob_cartera..ca_rubro_op
                                 where  ro_operacion = x.op_operacion
                                 and   ro_concepto  = @w_nemonico_int),
           @w_fecha_ini    = op_fecha_ini,
           @w_periodicidad_pago = isnull((select td_descripcion from cob_cartera..ca_tdividendo
                                  where td_tdividendo = x.op_tdividendo), 'NA'),

           @w_promotor     = isnull((select fu_nombre from cobis..cc_oficial, cobis..cl_funcionario
                              where oc_oficial = x.op_oficial
                              and  oc_funcionario = fu_funcionario), 'NA'),
           @w_tipo_operacion = isnull(op_toperacion, 'NA'),
           @w_moneda         = isnull(op_moneda, 0),
           @w_tipo_tramite   = isnull((select tr_tipo from cob_credito..cr_tramite where tr_tramite = x.op_tramite), 'NA')
    from cob_cartera..ca_operacion x
    where op_banco = @i_banco


    --select @w_tasa_anual_fija = cast(@w_tasa_int as varchar) + '%'

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



    select @w_simbolo = mo_simbolo 
    from cobis..cl_moneda
    where mo_moneda = @w_moneda


    --Obtiene el RECA del documento

    select @w_reca = id_dato 
    from cob_credito..cr_imp_documento
    where id_toperacion = @w_tipo_operacion
    and   id_moneda     = @w_moneda
    and   id_mnemonico  = @i_nemonico
    and   id_tipo_tramite = @w_tipo_tramite


    select @w_plazo_frecuencia   = cast(@w_plazo as varchar) + ' ' + @w_desc_frecuencia


--print 'monto moneda: ' + cast(@w_monto_moneda as varchar)
--print '@w_monto_pagar_moneda: ' + cast(@w_monto_pagar_moneda as varchar)
--print '@w_plazo_frecuencia: ' + cast(@w_plazo_frecuencia as varchar)
--print '@w_tasa_anual_fija: ' + cast(@w_tasa_anual_fija as varchar)


    --Devuelve los valores del FE
    select isnull(@w_sucursal, 'NA'),               --1
           @w_grupo,
           @w_ciclo,
           @w_nombre_grupo,
           @w_nro_cuenta,             --5
           @w_nro_credito,
           @w_monto,
           @w_monto_pagar,
           @w_plazo_frecuencia,
           @w_frecuencia,             --10
           @w_tasa_int,
           @w_fecha_ini,
           @w_periodicidad_pago,
           @w_promotor,
           isnull(@w_simbolo,'NA'),
           isnull(@w_reca, 'NA'),
           @w_tipo_operacion
          
           



end 

--------------------------------------
--Detalle de la tabla de amortizacion
--------------------------------------

if @i_tipo = 'D'
begin

if @i_banco is NULL
begin

      select @w_error = 70203
      goto ERROR

end



select 'No'                 = 0,   
       'Fecha Limite'       = op_fecha_liq,  
       'Saldo Inicial'      = op_monto,
       'Pago Interes'       = isnull((select isnull(ro_valor,0) from cob_cartera..ca_rubro_op 
                                where ro_operacion = x.op_operacion
                                 and  ro_concepto  = @w_nemonico_comdes),0),
       'IVA Intereses'      = isnull((select isnull(ro_valor,0) from cob_cartera..ca_rubro_op 
                                where ro_operacion = x.op_operacion
                                 and  ro_concepto  = @w_nemonico_ivacod),0),  
       'Pago Principal'     = '-',
       'Pago Otros Rubros'  = '-',
       'Pago Total'         = '-',
       'Saldo Insoluto'     =  op_monto
   from cob_cartera..ca_operacion x
   where  op_banco = @i_banco
   UNION

select 'No'                 = di_dividendo,   
       'Fecha Limite'       = di_fecha_ven,  
       'Saldo Inicial'      = (select case when x.di_dividendo = 1 then
	                              (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap)
                                      else
                                      (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap
                             		and  am_dividendo > x.di_dividendo - 1)
                                       end),
      'Pago Interes'       = (select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_int),

       'IVA Intereses'      = isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_ivaint),0),  
             
       'Pago Principal'     = (select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_cap),
       

      'Pago Otros Rubros'  = isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  not in (@w_nemonico_cap, @w_nemonico_int, @w_nemonico_ivaint)),0),

       'Pago Total'         = (select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo),

       'Saldo Insoluto'     =  (select isnull(sum(am_cuota),0) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap
                             		and  am_dividendo > x.di_dividendo )               
from cob_cartera..ca_operacion, 
     cob_cartera..ca_dividendo x
where  op_banco = @i_banco
and    di_operacion = op_operacion



end





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

