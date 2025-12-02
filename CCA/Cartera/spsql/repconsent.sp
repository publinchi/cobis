/******************************************************************/
/*  Archivo:            repconsent.sp                             */
/*  Stored procedure:   sp_rep_consentimiento                     */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 13-Ago-2019                               */
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
/*   - Genera la data para reporte de consentimiento de op. Gru-  */
/*     pales.                                                     */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR           RAZON                      */
/*  13/Ago/19        Lorena Regalado   Genera informacion         */
/*                                     Reporte Consentimiento     */
/* 31/Ene/2020       RIGG        Ajuste redondeo cantidades       */
/* 19/Feb/2020       RIGG   Se agrega app materno en consulta     */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_rep_consentimiento') IS NOT NULL
	DROP PROCEDURE dbo.sp_rep_consentimiento
GO

create proc sp_rep_consentimiento
   @t_trn              int          = 77527,
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
   @i_banco            varchar(15)
 
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
   @w_desc_frecuencia      varchar(30),
   @w_nemonico_comdes      catalogo,
   @w_nemonico_ivacod      catalogo,
   @w_monto_grupal         money,
   @w_monto_ahorro         money,
   @w_op_renovada          int,
   @w_op_banco_anterior    cuenta,
   @w_tipo_tramite         char(1),
   @w_secuencial_pago      int,
   @w_monto_liquida        money,
   @w_deposito_inicial     money,
   @w_nro_certificado      catalogo


select @w_deposito_inicial = 0,
       @w_nro_certificado  = ' '





if @i_banco is not NULL
begin
    if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @i_banco
                    and op_admin_individual = 'N'
                    and op_grupal = 'S')
    begin
       select @w_error = 70203
       goto   ERROR
    end
end

--Obtengo datos de la Operacion Grupal

select @w_monto_grupal = op_monto,
       @w_operacion    = op_operacion,
       @w_grupo        = op_grupo,
       @w_tipo_tramite = tr_tipo,
       @w_op_banco_anterior  = op_anterior
from cob_cartera..ca_operacion, cob_credito..cr_tramite
where op_banco   = @i_banco
and   op_tramite = tr_tramite


--Obtengo el Monto de Ahorro M¡nimo
select @w_monto_ahorro = ci_monto_ahorro 
from cob_cartera..ca_ciclo 
where ci_operacion = @w_operacion
and   ci_grupo     = @w_grupo

--print 'Monto ahorro ' + cast(@w_monto_ahorro as varchar)

--Bloque de Renovaciones
if @w_tipo_tramite = 'R' 
begin
   select @w_op_renovada = op_operacion
   from cob_cartera..ca_operacion
   where op_banco = @w_op_banco_anterior

   select @w_secuencial_pago = max(ab_secuencial_pag) 
   from cob_cartera..ca_abono 
   where ab_operacion = @w_op_renovada 
   and   ab_estado = 'A'


   select @w_monto_liquida = isnull(abd_monto_mpg,0)
   from ca_abono, ca_abono_det 
   where ab_operacion = @w_op_renovada 
   and   ab_estado = 'A'
   and   ab_secuencial_pag = @w_secuencial_pago
   and   ab_operacion      = abd_operacion
   and   ab_secuencial_ing = abd_secuencial_ing   


--print 'Op renovada: ' + cast(@w_op_renovada as varchar)
--print '@w_monto_liquida: ' + cast(@w_monto_liquida as varchar)


end  -- if @w_tipo_tramite = 'R'

--print '@w_monto_grupal: ' + cast(@w_monto_grupal as varchar)


select 'Orden'            = (select case when cg_rol = 'P' then 1
                                         when cg_rol = 'T' then 2
                                         when cg_rol = 'S' then 3
                                    else 4
                                    end
                            from cobis..cl_cliente_grupo, cobis..cl_tabla z, cobis..cl_catalogo y 
                            where cg_grupo = x.op_grupo 
                            and cg_ente   = x.op_cliente
                            and  z.tabla = 'cl_rol_grupo'
                            and   z.codigo = y.tabla
                            and   y.codigo  = cg_rol
                            and   y.estado = 'V' ),
       'ClienteMiembro'   = op_cliente,
       'OperacionHija'    = op_operacion,
       'NoOperacion'      = op_ref_grupal, 
       'RolDesc'          = (select y.valor from cobis..cl_cliente_grupo, cobis..cl_tabla z, cobis..cl_catalogo y 
                            where cg_grupo = x.op_grupo 
                            and cg_ente   = x.op_cliente
                            and  z.tabla = 'cl_rol_grupo'
                            and   z.codigo = y.tabla
                            and   y.codigo  = cg_rol
                            and   y.estado = 'V' ),
       'NoCliente'        = (select substring(p_p_apellido,1,20) + ' ' + substring(p_s_apellido,1,20) + ' ' + substring(en_nombre,1,20) +' ' + substring(p_s_nombre,1,20)
                            from cobis..cl_ente
                            where en_ente = x.op_cliente),
       'MontoCredito'     = op_monto,
       'MontoAhorro'      = convert(decimal(10,2),(round(((op_monto/@w_monto_grupal) * 100),2) * @w_monto_ahorro))/100,  --Prorrateado por cada operacion hija
       'MontoLiquidacion' = (select case when @w_tipo_tramite in ('R') then
                                                                      convert(decimal(10,2),((round(((x.op_monto/@w_monto_grupal) * 100),2) * @w_monto_liquida)/100))
                                                                  else 0
                                                                  end),
       'ValorSegBasico'   = isnull((select so_monto_seguro from cob_cartera..ca_seguros_op
                             where so_operacion = x.op_operacion
                             and   so_tipo_seguro = 'B'),0),
       'ValorSegVoluntario' = isnull((select sum(so_monto_seguro) from cob_cartera..ca_seguros_op
                             where so_operacion = x.op_operacion
                             and   so_tipo_seguro <> 'B'),0),
       'DepositoInicial' = @w_deposito_inicial,
       'MontoEntregar' = 0,

       'ProgramaPrevencion' = isnull((select valor from cobis..cl_tabla z, cobis..cl_catalogo y
                               where z.tabla = 'ca_tipo_seguro'
                                and   z.codigo = y.tabla
                                and   y.codigo  = (select so_tipo_seguro from cob_cartera..ca_seguros_op 
                                                    where so_operacion = x.op_operacion
                                                    and   so_tipo_seguro = 'OPR') 
                                and   y.estado = 'V'), null),
       'NoCertificado' = @w_nro_certificado,  --enviar valor vacio
       'FechaVigencia' = (select isnull(convert(varchar(10),so_fecha_fin,101),null) 
       --'FechaVigencia' = (select so_fecha_fin 
                          from cob_cartera..ca_seguros_op
                          where so_operacion = x.op_operacion
                           and  so_tipo_seguro = 'B'),
       'Beneficiario'  = (isnull(bs_apellido_paterno,' ') +' '+isnull(bs_apellido_materno,' ')+ ' ' + isnull(bs_nombres,' ')) ,
       'Parentesco'    = (select valor from cobis..cl_tabla x, cobis..cl_catalogo y
                          where x.tabla = 'cl_parentesco_beneficiario'
                          and   x.codigo = y.tabla
                          and   y.codigo  = b.bs_parentesco
                          and   y.estado = 'V' ),
       'PorcAsignado'     = bs_porcentaje
into #reporte_final
from ca_operacion x, cobis..cl_beneficiario_seguro b, cob_credito..cr_tramite
where op_grupal = 'S' 
and  op_ref_grupal = @i_banco
and  bs_producto = 7
and  bs_nro_operacion = op_operacion
and  op_tramite = tr_tramite


select isnull(OperacionHija,0),
       isnull(NoOperacion, ' '),
       isnull(RolDesc,' '),
       isnull(NoCliente,' '),
       isnull(round(MontoCredito,2),0),
       isnull(round(MontoAhorro,2),0),
       isnull(round(MontoLiquidacion,2),0),
       isnull(round(ValorSegBasico,2),0),
       isnull(round(ValorSegVoluntario,2),0),
       isnull(DepositoInicial,0),
       isnull(round((MontoCredito + MontoAhorro - MontoLiquidacion - ValorSegBasico - ValorSegVoluntario - DepositoInicial),0),2) as 'MontoEntregar',
       isnull(ProgramaPrevencion,' '),
       isnull(NoCertificado,' '),
       isnull(FechaVigencia, ' '),
       isnull(Beneficiario,' '),
       isnull(Parentesco,' '),
       isnull(PorcAsignado,0),
       isnull(ClienteMiembro,0)
from #reporte_final
order by Orden, OperacionHija



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

