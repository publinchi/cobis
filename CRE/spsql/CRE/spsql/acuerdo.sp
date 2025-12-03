/************************************************************************/
/*  Archivo:                acuerdo.sp                                  */
/*  Stored procedure:       sp_acuerdo                                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_acuerdo' and type = 'P')
   drop proc sp_acuerdo
go

create proc sp_acuerdo


@s_ssn                  int          = null,


@s_user                 login        = null,


@s_ofi                  int          = null,


@s_rol                  int          = null,


@s_date                 datetime     = null,


@t_trn                  int          = null,


@t_debug                char(1)      = 'N',


@t_file                 varchar(10)  = null,


@i_modo                 char(1)      = null,


@i_banco                cuenta       = null,


@i_acuerdo              int          = null,


@i_tipo_acuerdo         char(1)      = null,


@i_fecha_pry            datetime     = null,


@i_rol                  tinyint      = null,


@i_producto             int          = null,


@i_cuotas_ven           int          = null,


@i_dias_mora            int          = null,


@i_saldo_cap            money        = null,


@i_saldo_int            money        = null,


@i_saldo_imo            money        = null,


@i_saldo_honabo         money        = null,


@i_saldo_ivahonabo      money        = null,


@i_saldo_otros          money        = null,


@i_saldo_int_pry        money        = null,


@i_saldo_imo_pry        money        = null,


@i_saldo_honabo_pry     money        = null,


@i_saldo_ivahonabo_pry  money        = null,


@i_saldo_otros_pry      money        = null,


@i_cap_cond             money        = null,


@i_int_cond             money        = null,


@i_imo_cond             money        = null,


@i_otr_cond             money        = null,


@i_int_cond_pry         money        = null,


@i_imo_cond_pry         money        = null,


@i_otr_cond_pry         money        = null,


@i_formato_fecha        tinyint      = 101,


@i_cambio_regalo        varchar(2)   = 'N',


@i_cambio_plan_pago     varchar(2)   = 'N',


@i_fecha                datetime     = null,


@i_monto                money        = null,


@i_abono                money        = null,


@i_honoiva              money        = null,


@i_gracia               smallint     = null,


@i_estado_ac            char(1)      = null,


@i_ssn                  int          = null,


@i_user                 login        = null,


@i_borrar_tmp           char(1)      = null,


@i_fecha_ult_proc       datetime     = null,


@i_estado               char(2)      = null,


@i_porc_cond_cap        float        = null,


@i_porc_cond_int        float        = null,


@i_porc_cond_imo        float        = null,


@i_porc_cond_otr        float        = null,


@i_max_dias_ac          smallint     = null,


@i_operacion            char(1)      = null,


@i_pago_cubierto        char(1)      = 'N',


@o_acuerdo              int          = null  out


as





declare


@w_error                 int,


@w_sp_name               varchar(32),


@w_msg                   varchar(255),


@w_operacion             int,


@w_cap                   money,


@w_int                   money,


@w_imo                   money,


@w_hon                   money,


@w_ivahon                money,


@w_otr                   money,


@w_cap_pry               money,


@w_int_pry               money,


@w_imo_pry               money,


@w_hon_pry               money,


@w_ivahon_pry            money,


@w_otr_pry               money,


@w_oficina               smallint,


@w_toperacion            catalogo,


@w_estado_op             tinyint,


@w_estado_cobranza       catalogo,


@w_calificacion          char(1),


@w_ente                  int,


@w_nombre                varchar(255),


@w_desc_oficina          descripcion,


@w_desc_estado_op        descripcion,


@w_desc_estado_cob       descripcion,


@w_ced_ruc               numero,


@w_direccion             tinyint,


@w_dir_descripcion       varchar(255),


@w_desc_ciudad           descripcion,


@w_telefono              varchar(30),


@w_saldo_cap             money,


@w_dias_mora             smallint,


@w_cuotas_ven            smallint,


@w_estado_ac             char(1),


@w_tipo_acuerdo          char(1),


@w_desc_estado_ac        descripcion,


@w_desc_tipo_ac          descripcion,


@w_fecha_ing             datetime,


@w_fecha_pry             datetime,


@w_valor                 float,


@w_moneda                tinyint,


@w_num_dec               tinyint,


@w_secuencial            int,


@w_fecha_ult_proceso     datetime,


@w_porc_cond_cap         money,


@w_porc_cond_int         money,


@w_porc_cond_imo         money,


@w_porc_cond_otr         money,


@w_cap_cond              money,


@w_int_cond              money,


@w_imo_cond              money,


@w_otr_cond              money,


@w_int_cond_pry          money,


@w_imo_cond_pry          money,


@w_otr_cond_pry          money,


@w_fecha_pry_max         datetime,


@w_monto                 money,


@w_monto_letras          varchar(500),


@w_return                int,


@w_ac_estado             varchar(1),


@w_ac_banco              cuenta,


@w_ac_fecha_ingreso      datetime,


@w_op_fecha_ult_proceso  datetime,


@w_ac_secuencial_rpa     int,


@w_tabla                 smallint,


@w_fecha_plan            datetime,


@w_gracia                int,


@w_estado                varchar(10),


@w_valor_aux             varchar(20),


@w_valor_aux1            varchar(20),


@w_pos                   int,


@w_cont                  int,


@w_cont_dat_acu          int,


@w_salir                 tinyint,


@w_banco                 numero,


@w_max_dias_ac           smallint,


@w_fecha_pag_max         datetime,


@w_est_vencido           tinyint,


@w_est_cancelado         tinyint,


@w_param_cap             varchar(30),


@w_param_int             varchar(30),


@w_param_mora            varchar(30),


@w_monto_acuerdo         money,


@w_tipo_cobro            char(1),


@w_hon_tmp               money,


@w_ivahon_tmp            money,


@w_cap_acu        		 money,


@w_int_acu        		 money,


@w_imo_acu        		 money,


@w_otr_acu        		 money,


@w_pag_acu				 money,


@w_fecha_vencimiento     datetime,


@w_ciudad                int,


@w_siguiente_dia         datetime,


@w_primer_acuerdo        tinyint,


@w_pago_cubierto         char(1),


@w_vx_valor_vencido      MONEY,

@w_min_ac_fecha_proy     DATETIME





select @w_sp_name = 'sp_acuerdo'





if @t_debug = 'S' print '@i_modo  ' +  cast(@i_modo  as varchar)





-- ESTADOS DE CARTERA


exec @w_error = cob_cartera..sp_estados_cca


@o_est_vencido    = @w_est_vencido   out,


@o_est_cancelado  = @w_est_cancelado out





if @w_error <> 0


   goto ERROR








-- PARAMETROS DE CONCEPTOS


select @w_param_cap = pa_char


from   cobis..cl_parametro


where  pa_nemonico = 'CAP'


and    pa_producto = 'CCA'





if @@rowcount = 0


begin


   select @w_error = 701060


   goto ERROR


end





select @w_param_int = pa_char


from   cobis..cl_parametro


where  pa_nemonico = 'INT'


and    pa_producto = 'CCA'





if @@rowcount = 0


begin


   select @w_error = 701059


   goto ERROR


end





select @w_param_mora = pa_char


from   cobis..cl_parametro


where  pa_nemonico = 'IMO'


and    pa_producto = 'CCA'





if @@rowcount = 0


begin


   select @w_error = 701084


   goto ERROR


end








-- CONSULTA DE DATOS DE LA OPERACION ASOCIADA AL ACUERDO


if @i_modo = 'O'


begin


   --CONSULTA SI EXISTE ACUERDO VIGENTE


   if exists(select 1 from cr_acuerdo where ac_banco = @i_banco and ac_estado = 'V')


      select


      @o_acuerdo       = ac_acuerdo,


      @w_tipo_acuerdo  = ac_tacuerdo,


      @w_fecha_pry     = ac_fecha_proy,


      @w_estado_ac     = ac_estado,


      @w_fecha_ing     = ac_fecha_ingreso,


      @w_pago_cubierto = ac_pago_cubierto


      from cr_acuerdo


      where ac_banco      = @i_banco and ac_estado = 'V'


      and   ac_fecha_proy = (select max(ac_fecha_proy) from cr_acuerdo where ac_banco = @i_banco)





   -- CONSULTA DE DATOS DE LA OPERACION


   select


   @w_operacion          = op_operacion,


   @w_oficina            = op_oficina,


   @w_toperacion         = op_toperacion,


   @w_estado_op          = op_estado,


   @w_estado_cobranza    = op_estado_cobranza,


   @w_calificacion       = op_calificacion,


   @w_ente               = op_cliente,


   @w_nombre            = op_nombre,


   @w_fecha_ult_proceso  = op_fecha_ult_proceso


   from cob_cartera..ca_operacion


   where op_banco = @i_banco





   if @@rowcount = 0


   begin


      select @w_error = 701013


      goto ERROR


   end





   select   @w_vx_valor_vencido = vx_valor_vencido


   from     cob_cartera..ca_valor_atx


   where    vx_banco = @i_banco





   exec @w_return = cob_cartera..sp_saldo_honorarios


   @i_banco     = @i_banco,


   @i_saldo_cap = @w_vx_valor_vencido,


   @o_saldo_hon = @w_hon out,


   @o_saldo_iva = @w_ivahon out





   if @w_return <> 0


   begin


       select @w_error = @w_return


       goto ERROR


   end





   select @w_vx_valor_vencido = @w_vx_valor_vencido + @w_hon + @w_ivahon


   -- CONSULTA DESCRIPCION DE LA OFICINA


   select @w_desc_oficina = of_nombre


   from cobis..cl_oficina


   where of_oficina = @w_oficina





   -- CONSULTA DESCRIPCION DE ESTADO DE OPERACION


   select @w_desc_estado_op = es_descripcion


   from cob_cartera..ca_estado


   where es_codigo = @w_estado_op





   -- CONSULTA DESCRIPCION DE ESTADO DE COBRANZA


   select @w_desc_estado_cob = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_estado_cobranza'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_estado_cobranza





   -- CONSULTA DE CEDULA DEL TITULAR DE CREDITO


   select


   @w_ced_ruc = en_ced_ruc


   from cobis..cl_ente


   where en_ente = @w_ente





   -- CONSULTA DE DIRECCION PRINCIPAL


   select


   @w_direccion       = di_direccion,


   @w_dir_descripcion = di_descripcion,


   @w_desc_ciudad     = ci_descripcion


   from cobis..cl_direccion, cobis..cl_ciudad


   where di_ente      = @w_ente


   and   di_principal = 'S'


   and   ci_ciudad    = di_ciudad





   -- CONSULTA DE TELEFONO ASOCIADO A LA DIRECCION PRINCIPAL


   select @w_telefono = isnull(nullif(rtrim(ltrim(te_prefijo)) + '-', '-'), '') + rtrim(ltrim(te_valor))

   from cobis..cl_telefono


   where te_ente      = @w_ente


   and   te_direccion = @w_direccion





   select


   di_dividendo,


   di_estado,


   di_fecha_ven,


   di_gracia


   into #dividendo


   from cob_cartera..ca_dividendo


   where di_operacion = @w_operacion


   and   di_estado   <> @w_est_cancelado





   /* JAR REQ 230 - INCLUIR CALCULO DE SALDO DE HONORARIOS */


   if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230


               where hm_estado_cobranza = @w_estado_cobranza)


   begin





      /* INCLUIR CALCULO DE SALDO DE HONORARIOS */


      exec @w_return    = cob_cartera..sp_saldo_honorarios


      @i_banco          = @i_banco,


      @i_num_dec        = @w_num_dec,


      @o_saldo_tot      = @w_saldo_cap out





      if @w_return <> 0


      begin


         select @w_error = @w_return


         goto ERROR


      end





      select @w_saldo_cap = isnull(@w_saldo_cap, 0)


   end


   else


   begin





      /** SALDO TOTAL DE LA OPERACION   **/


      exec @w_return   = cob_cartera..sp_calcula_saldo


      @i_operacion     = @w_operacion,


      @i_tipo_pago     = 'A', --@w_anticipado_int,


      @o_saldo         = @w_saldo_cap out





      if @w_return <> 0


      begin


         select @w_error = @w_return


         goto ERROR


      end








      select @w_saldo_cap = isnull(@w_saldo_cap,0)


   end





   -- CONSULTA DE DIAS MORA


   select @w_dias_mora = max(case when datediff(dd, di_fecha_ven, @w_fecha_ult_proceso) - di_gracia > 0 then datediff(dd, di_fecha_ven,
@w_fecha_ult_proceso) else 0 end)

   from #dividendo





   -- CONSULTA CUOTAS VENCIDAS


   select @w_cuotas_ven = count(1)


   from #dividendo


   where di_estado = @w_est_vencido





   select @w_desc_estado_ac = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_estado_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_estado_ac





   select @w_desc_tipo_ac = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_tipo_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_tipo_acuerdo





   select


   @w_desc_oficina,                                              -- 1


   @w_desc_estado_op,                                            -- 2


   @w_toperacion,                                                -- 3


   @w_desc_estado_cob,                                           -- 4


   @w_saldo_cap,                                                 -- 5


   @w_calificacion,                                              -- 6


   @w_dias_mora,                                                 -- 7


   @w_cuotas_ven,                                                -- 8


   @w_ced_ruc,                                                   -- 9


   @w_nombre,                                                    -- 10


   @w_dir_descripcion,                                           -- 11


   @w_telefono,                                                  -- 12


   @w_desc_ciudad,                                               -- 13


   convert(varchar(10), @w_fecha_ult_proceso, @i_formato_fecha), -- 14


   @o_acuerdo,                                                   -- 15


   @w_tipo_acuerdo,                                              -- 16


   @w_desc_tipo_ac,                                              -- 17


   @w_estado_ac,                                                 -- 18


   @w_desc_estado_ac,                                            -- 19


   convert(varchar(10), @w_fecha_ing, @i_formato_fecha),         -- 20


   convert(varchar(10), @w_fecha_pry, @i_formato_fecha),         -- 21


   @w_pago_cubierto,                                             -- 22


   @w_vx_valor_vencido                                           -- 23


end





-- CONSULTA DE DATOS DEL ACUERDO


if @i_modo = 'A'


begin





   select


   @w_banco             = ac_banco,


   @w_estado_ac         = ac_estado,


   @w_fecha_ing         = ac_fecha_ingreso,


   @w_tipo_acuerdo      = ac_tacuerdo,


   @w_fecha_pry         = ac_fecha_proy,


   @w_ac_secuencial_rpa = ac_secuencial_rpa


   from cr_acuerdo


   where ac_acuerdo = @i_acuerdo


   and   ac_fecha_proy = (select min(ac_fecha_proy) from cr_acuerdo where ac_acuerdo = @i_acuerdo)

   if @@rowcount = 0


   begin


      select @w_error = 2108033


      goto ERROR


   end





   select @w_desc_estado_ac = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_estado_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_estado_ac





   select @w_desc_tipo_ac = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_tipo_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_tipo_acuerdo





   select


   @w_banco,


   @w_estado_ac,


   @w_desc_estado_ac,


   convert(varchar(10), @w_fecha_ing, @i_formato_fecha),


   @w_tipo_acuerdo,


   @w_desc_tipo_ac,


   convert(varchar(10), @w_fecha_pry, @i_formato_fecha),


   @w_ac_secuencial_rpa





end








-- CONSULTA SALDOS DE LA OPERACION ASOCIADA AL ACUERDO


if @i_modo = 'S'


begin


   create table #saldos(


   sec      tinyint      not null,


   descr    descripcion  not null,


   cap      money            null,


   int      money            null,


   imo      money            null,


   honoabo  money            null,


   ivahono  money            null,


   otr      money            null,


   total    money            null,


   tipo     char(1)      not null


   )








   select top 1 fecha=ac_fecha_proy into #acuerdo from cr_acuerdo where ac_banco = @i_banco


   --if exists (select 1 from #acuerdo where fecha = @i_fecha_pry)


   if exists(select 1 from cr_acuerdo where ac_banco = @i_banco and ac_estado = 'V')


      select @w_primer_acuerdo = 1


   else


      select @w_primer_acuerdo = 0





   select


   @w_operacion         = op_operacion,


   @w_fecha_ult_proceso = op_fecha_ult_proceso,


   @w_moneda            = op_moneda


  from cob_cartera..ca_operacion


   where op_banco = @i_banco





   if @@rowcount = 0


   begin


      select @w_error = 701013


      goto ERROR


   end





   -- CONTROL DEL NUMERO DE DECIMALES


   exec @w_error = cob_cartera..sp_decimales


   @i_moneda       = @w_moneda,


   @o_decimales    = @w_num_dec out





   if @w_error <> 0


      goto ERROR





   -- CUANDO LA CONSULTA ES PARA INGRESO O MODIFICACION SE CONSULTAS LOS DIAS MAXIMOS PARAMETRIZADOS

   if @i_operacion in ('I', 'M')


   begin


      exec @w_error = cob_cartera..sp_matriz_valor


      @i_matriz    = 'DIASMAXNEG',


      @i_fecha_vig = @w_fecha_ult_proceso,


      @i_eje1      = @i_tipo_acuerdo,


      @i_eje2      = @i_rol,


      @o_valor     = @w_max_dias_ac out,


      @o_msg       = @w_msg   out





      if @w_error <> 0


         goto ERROR


   end





   if exists(select 1 from cr_acuerdo where


                      ac_acuerdo = @i_acuerdo


              and ac_fecha_proy = @i_fecha_pry)


   begin





      select


      @w_fecha_ing         = ac_fecha_ingreso,


      @w_cap               = ac_saldo_cap,


      @w_int               = ac_saldo_int,


      @w_imo               = ac_saldo_imo,


      --@w_hon               = ac_saldo_honabo,


      --@w_ivahon            = ac_saldo_ivahonabo,


      @w_otr               = ac_saldo_otros,


      --@w_cap_pry           = ac_saldo_cap,


      @w_int_pry           = ac_saldo_int_pry,


      @w_imo_pry           = ac_saldo_imo_pry,


      --@w_hon_pry           = ac_saldo_honabo_pry,


      --@w_ivahon_pry        = ac_saldo_ivahonabo_pry,


      @w_otr_pry           = ac_saldo_otros_pry,


      @w_ac_secuencial_rpa = ac_secuencial_rpa,


      @w_porc_cond_cap     = ac_porc_cond_cap,


      @w_porc_cond_int     = ac_porc_cond_int,


      @w_porc_cond_imo     = ac_porc_cond_imo,


      @w_porc_cond_otr     = ac_porc_cond_otr,


      @w_max_dias_ac       = isnull(@w_max_dias_ac, ac_max_dias_ac)


      from cr_acuerdo


      where ac_acuerdo = @i_acuerdo and ac_fecha_proy = @i_fecha_pry





      select @w_cap_acu = sum(ac_cap_cond),


             @w_int_acu = sum(ac_int_cond),


             @w_imo_acu = sum(ac_imo_cond),


             @w_otr_acu = sum(ac_otr_cond),


             @w_pag_acu = sum(av_neto)


      from   cr_acuerdo, cr_acuerdo_vencimiento


      where ac_banco = @i_banco


      and   ac_fecha_proy  <= @i_fecha_pry


      and   av_fecha       = ac_fecha_proy


      and   ac_acuerdo     = av_acuerdo


/*


      print 'cr_acuerdo.sp @w_cap_pry   ' + cast(@w_cap_pry as varchar)   +


                         ' @w_pag_acu   ' + cast(@w_pag_acu as varchar)   +


                         ' @w_int       ' + cast(@w_int as varchar)       +


                         ' @w_imo       ' + cast(@w_imo as varchar)       +


                         ' @w_otr       ' + cast(@w_otr as varchar)       +


                         ' @i_fecha_pry ' + cast(@i_fecha_pry as varchar) +


                         ' @w_banco     ' + cast(@i_banco as varchar)

*/





      exec @w_error = cob_cartera..sp_proyeccion_rubro


      @i_operacionca  = @w_operacion,


      @i_tipo_acuerdo = @i_tipo_acuerdo,


      @i_fecha_pry    = @i_fecha_pry,


      @o_cap_pry      = @w_cap_pry         out





      --print @w_cap_pry





      --select @w_cap_pry = (isnull(@w_cap_pry,0) - ( isnull(@w_pag_acu,0) -(isnull(@w_int,0)+ isnull(@w_imo,0) + isnull(@w_otr,0)) )) - isnull(@w_cap_acu,0)




      select @w_fecha_pag_max = dateadd(dd, @w_max_dias_ac, @w_fecha_ing)





      insert into #saldos(


      sec,              descr,


      cap,              int,              imo,


      honoabo,          ivahono,          otr,


      total,


      tipo)


      select


      1,                'SALDOS A LA FECHA',


      @w_cap,           @w_int,           @w_imo,


      0,                0,        @w_otr,


      @w_cap + @w_int + @w_imo + @w_otr,


      'M'





      insert into #saldos(


      sec,              descr,


      cap,              int,              imo,


      honoabo,          ivahono,          otr,


      total,


      tipo)


      select


      2,                'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS',


      case when @w_cap_pry < 0 then 0 else @w_cap_pry end,


      case when @w_int_pry < 0 then 0 else @w_int_pry end,


      case when @w_imo_pry < 0 then 0 else @w_imo_pry end,


      0,        0,


      case when @w_otr_pry < 0 then 0 else @w_otr_pry end,


      @w_cap_pry + @w_int_pry + @w_imo_pry + @w_otr_pry,


      'M'


   end


   else


   begin


      -- VALIDACION DE LA FECHA DE PROYECCION


      select @w_fecha_pry_max = dateadd(dd, @w_max_dias_ac, @w_fecha_ult_proceso)





      if @i_fecha_pry > @w_fecha_pry_max


      begin


         select @w_error = 2108034


         goto ERROR


      end





      select @w_fecha_pag_max = @w_fecha_pry_max





      exec @w_error = cob_cartera..sp_proyeccion_rubro


      @i_operacionca  = @w_operacion,


      @i_acuerdo      = @i_acuerdo,


      @i_tipo_acuerdo = @i_tipo_acuerdo,


      @i_fecha_pry    = @i_fecha_pry,


      @o_cap          = @w_cap             out,


      @o_int          = @w_int             out,


      @o_imo          = @w_imo             out,


      @o_hon          = @w_hon             out,


      @o_ivahon       = @w_ivahon          out,


      @o_otr          = @w_otr             out,


      @o_cap_pry      = @w_cap_pry         out,


      @o_int_pry      = @w_int_pry         out,


      @o_imo_pry      = @w_imo_pry         out,


      --@o_hon_pry      = @w_hon_pry         out,


      --@o_ivahon_pry   = @w_ivahon_pry      out,


      @o_otr_pry      = @w_otr_pry         out





      if @w_error <> 0


         goto ERROR





      insert into #saldos(


      sec,              descr,


      cap,              int,              imo,


      honoabo,          ivahono,          otr,


      total,


      tipo)


      select


      1,                'SALDOS A LA FECHA',


      @w_cap,           @w_int,           @w_imo,


      0,                0,        @w_otr,


      @w_cap + @w_int + @w_imo + @w_otr,


      'M'





      insert into #saldos(


      sec,              descr,


      cap,              int,              imo,


      honoabo,          ivahono,          otr,


      total,


      tipo)


      select


      2,                'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS',


      case when @w_cap_pry < 0 then 0 else @w_cap_pry end,


      case when @w_int_pry < 0 then 0 else @w_int_pry end,


      case when @w_imo_pry < 0 then 0 else @w_imo_pry end,


      0,                       0,


      case when @w_otr_pry < 0 then 0 else @w_otr_pry end,


      @w_cap_pry + @w_int_pry + @w_imo_pry + @w_otr_pry,


      'M'


   end





   -- SI EL PREMIO NO HA SIDO APLICADO Y LA CONSULTA ES PARA INGRESO O MODIFICACION DEL ACUERDO


   -- SE ACTUALIZAN LOS PORCENTAJES DE CONDONACION


   if @w_ac_secuencial_rpa is null and @i_operacion in ('I', 'M', 'C')


   begin


      -- DETERMINACION DE PORCENTAJES POR RUBRO





      create table #rubros(


      concepto   varchar(10) null,


      valor      money       null,


      porc       float       null)


      --print 'cr_acuerdo.sp ' + @i_banco


      exec @w_error = cob_cartera..sp_condonaciones


      @s_user         = @s_user,


      @s_date         = @s_date,


      @s_ofi          = @s_ofi ,


      @s_rol          = @s_rol,


      @s_ssn          = @s_ssn,


      @i_banco        = @i_banco,


      @i_operacion    = 'S',


      @i_opcion       = 'U'





      if @w_error <> 0


         goto ERROR





      select @w_porc_cond_cap = isnull(porc,0.00) from #rubros where concepto = 'CAP'


      select @w_porc_cond_int = isnull(porc,0.00) from #rubros where concepto = 'INT'


      select @w_porc_cond_imo = isnull(porc,0.00) from #rubros where concepto = 'IMO'


      select @w_porc_cond_otr = isnull(porc,0.00) from #rubros where concepto = 'OTROS'





   end





   insert into #saldos(


   sec,                 descr,


   cap,                 int,                 imo,


   honoabo,             ivahono,             otr,


   total,               tipo)


   select


   3,                   'PORCENTAJE DE CONDONACION',


   @w_porc_cond_cap,    @w_porc_cond_int,    @w_porc_cond_imo,


   0,                   0,                   @w_porc_cond_otr,


   null,                'P'





   /*select @w_cap_acu = round(SP.cap - SA.cap, @w_num_dec),


          @w_int_acu = round(SP.int - SA.int, @w_num_dec),


          @w_imo_acu = round(SP.imo - SA.imo, @w_num_dec),


          @w_otr_acu = round(SP.otr - SA.otr, @w_num_dec)


   from #saldos SA, #saldos SP


   where SA.descr = 'SALDOS A LA FECHA'


   and   SP.descr = 'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS'  */





   select @w_cap_acu = (@w_porc_cond_cap/100) * SP.cap,


          @w_int_acu = (@w_porc_cond_int/100) * SP.int,


          @w_imo_acu = (@w_porc_cond_imo/100) * SP.imo,


          @w_otr_acu = (@w_porc_cond_otr/100) * SP.otr


   from   #saldos SP


   where  SP.descr = 'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS'





   if @w_primer_acuerdo > 0 begin


      select @w_cap_acu = 0,


             @w_int_acu = 0,


             @w_imo_acu = 0,


             @w_otr_acu = 0


   end


   else begin


      if @w_cap_acu < 0


         select @w_cap_acu = 0


      if @w_int_acu < 0


         select @w_int_acu = 0


      if @w_imo_acu < 0


         select @w_imo_acu = 0


      if @w_otr_acu < 0


         select @w_otr_acu = 0


   end


   select @w_pag_acu = @w_cap_acu + @w_int_acu + @w_imo_acu + @w_otr_acu





   /*select @w_pag_acu = sum(valor)


   from #rubros*/





   /*print 'Acuerdo TOTAL MIN VALOR A CONDONAR:' +


         '@w_cap_acu : ' + cast(@w_cap_acu as varchar) +


         '@w_int_acu : ' + cast(@w_int_acu as varchar) +


         '@w_imo_acu : ' + cast(@w_imo_acu as varchar) +


         '@w_otr_acu : ' + cast(@w_otr_acu as varchar) +


         '@w_pag_acu : ' + cast(@w_pag_acu as varchar)*/





   --print 'cr_acuerdo No.: ' + cast(@w_primer_acuerdo as varchar)


   insert into #saldos(


   sec,              descr,                                                   -- 1


   cap,                                                                       -- 2


   int,                                                                       -- 3


   imo,                                                                       -- 4


   honoabo,                                                                   -- 5


   ivahono,                                                                   -- 6


   otr,                                                                       -- 7


   total,                                                                     -- 8


   tipo)                                                                      -- 9


   select


   5,                'MAX VALOR A CONDONAR',                                             -- 1


   case @w_primer_acuerdo when 0 then @w_cap_acu else 0 end,


   case @w_primer_acuerdo when 0 then @w_int_acu else 0 end,


   case @w_primer_acuerdo when 0 then @w_imo_acu else 0 end,


   0,                                                                                    -- 5


   0,                                                                                    -- 6


   case @w_primer_acuerdo when 0 then @w_otr_acu else 0 end,


   case @w_primer_acuerdo when 0 then isnull(@w_pag_acu ,0) else 0 end,


   'M'                                                                                   -- 9








   /*insert into #saldos


   select


   7,                      'TOTAL MINIMO A PAGAR',


   P.cap - M.cap,          P.int - M.int,          P.imo - M.imo,


   P.honoabo,              P.ivahono,              P.otr - M.otr,


   P.cap - M.cap + P.int - M.int + P.imo - M.imo + P.otr - M.otr,


   'M'


   from #saldos P, #saldos M


   where P.descr = 'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS'


   and   M.descr = 'MAX VALOR A CONDONAR'*/





   update MN


   set MN.int = MX.int


   from #saldos MX, #saldos MN


   where MX.descr = 'MAX VALOR A CONDONAR'


   and   MN.descr = 'MIN VALOR A CONDONAR'


   and   MN.int > MX.int





   update MN


   set MN.imo = MX.imo


   from #saldos MX, #saldos MN


   where MX.descr = 'MAX VALOR A CONDONAR'


   and   MN.descr = 'MIN VALOR A CONDONAR'


   and   MN.imo > MX.imo





   update MN


   set MN.cap = MX.cap


   from #saldos MX, #saldos MN


   where MX.descr = 'MAX VALOR A CONDONAR'


   and   MN.descr = 'MIN VALOR A CONDONAR'


   and   MN.cap > MX.cap





   update MN


   set MN.otr = MX.otr


   from #saldos MX, #saldos MN


   where MX.descr = 'MAX VALOR A CONDONAR'


   and   MN.descr = 'MIN VALOR A CONDONAR'


   and   MN.otr > MX.otr





   -- REAL A PAGAR POR HONORARIOS


   select


   @w_fecha_plan = '19000101',


   @w_hon        = 0,


   @w_ivahon     = 0





   select @w_monto_acuerdo = total


   from #saldos


   where descr = 'SALDOS PROYECTADOS MENOS PAGOS YA PACTADOS'





   exec @w_return = cob_cartera..sp_saldo_honorarios


      @i_banco     = @i_banco,


      @i_saldo_cap = @w_monto_acuerdo,


      @o_saldo_hon = @w_hon out,


      @o_saldo_iva = @w_ivahon out








     if @w_return <> 0


      begin


         select @w_error = @w_return


         goto ERROR


      end








   /*while 1 = 1


   begin


      select top 1


      @w_monto_acuerdo = av_monto,


      @w_fecha_plan    = av_fecha


      from cr_acuerdo_vencimiento


      where av_acuerdo = @i_acuerdo


      and   av_fecha   > @w_fecha_plan


      order by av_fecha





      if @@rowcount = 0


         break





      exec @w_error = cob_cartera..sp_calculo_honabo


      @i_consulta  = 'S',


      @i_banco     = @i_banco,


      @i_monto_mpg = @w_monto_acuerdo,


      @o_saldo_hon = @w_hon_tmp out,


      @o_saldo_iva = @w_ivahon_tmp out





      if @w_error <> 0


         goto ERROR





      select


      @w_hon    = @w_hon + @w_hon_tmp,


      @w_ivahon = @w_ivahon + @w_ivahon_tmp


   end*/





   insert into #saldos values(


   6,                      'REAL A PAGAR HONORARIOS',


   0,                      0,                      0,


   @w_hon,                 @w_ivahon,              0,


   @w_hon + @w_ivahon,


   'M' )





   /*update #saldos set


   honoabo = @w_hon,


   ivahono = @w_ivahon,


   total   = total + @w_hon + @w_ivahon


   where descr = 'TOTAL MINIMO A PAGAR'*/





   select


   ' '        = descr,


   'CAP'      = cap,


   'INT'      = int,


   'IMO'      = imo,


   'HONOABO'  = honoabo,


   'IVA/HONO' = ivahono,


   'OTROS*'   = otr,


   'TOTAL'    = total,


   ' '        = tipo


   from #saldos


   order by sec





   select convert(varchar(10), @w_fecha_pag_max, @i_formato_fecha)


   select @w_max_dias_ac


end





-- CONSULTA DEL PREMIO


if @i_modo = 'P'


begin





   select


   @w_cap_cond      = ac_cap_cond,


   @w_int_cond      = ac_int_cond,


   @w_imo_cond      = ac_imo_cond,


   @w_otr_cond      = ac_otr_cond,


   @w_int_cond_pry  = ac_int_cond_pry,


   @w_imo_cond_pry  = ac_imo_cond_pry,


   @w_otr_cond_pry  = ac_otr_cond_pry


   from cr_acuerdo


   where ac_acuerdo = @i_acuerdo


   and   ac_fecha_proy = (select min(ac_fecha_proy) from cr_acuerdo where ac_acuerdo = @i_acuerdo)




   select


   sec   = 1,


   rubro = 'OTROS*',


   --acum  = case @w_otr_cond when null then isnull(@w_otr_cond, 0) - isnull(@w_otr_cond_pry, 0) else 0 end,

   --proy  = case @w_otr_cond when null then isnull(@w_otr_cond_pry, 0) else 0 end,


   prem  = isnull(@w_otr_cond, 0)


   into #premio





   insert into #premio


   select


   2,


   @w_param_mora,


   --case @w_imo_cond when null then isnull(@w_imo_cond, 0) - isnull(@w_imo_cond_pry, 0) else 0 end,

   --case @w_imo_cond when null then isnull(@w_imo_cond_pry, 0) else 0 end,


   isnull(@w_imo_cond, 0)





   insert into #premio


   select


   3,


   @w_param_int,


   --case @w_int_cond when null then isnull(@w_int_cond, 0) - isnull(@w_int_cond_pry, 0) else 0 end,

   --case @w_int_cond when null then isnull(@w_int_cond_pry, 0) else 0 end,


   isnull(@w_int_cond, 0)





   insert into #premio


   select


   4,


   convert(varchar(10), @w_param_cap),


   --case @w_cap_cond when null then isnull(@w_cap_cond, 0) else 0 end,


   --convert(money, 0),


   isnull(@w_cap_cond, 0)





   insert into #premio


   select


   5,


   'TOTAL',


   --isnull(sum(acum), 0),


   --isnull(sum(proy), 0),


   isnull(sum(prem), 0)


   from #premio





   select


   'RUBRO '      = rubro,


   --'ACUMULADO ' =  acum ,


   --'PROYECTADO ' = proy,


   'PREMIO   ' =   prem


   from #premio


   order by sec


end





-- CONSULTA DEL PLAN DE PAGOS


if @i_modo = 'L'


begin


   select @w_tabla = codigo


   from cobis..cl_tabla


   where tabla = 'cr_estado_pag_acuerdo'





   select


   'FECHA PAGO '   = convert(varchar(10), av_fecha, @i_formato_fecha),


   'ABONO   '      = av_monto,


   'HONO/IVA   '    =isnull(av_hono,0) ,


   'VALOR NETO  '  = isnull(av_neto,0),


   'DIAS GRACIA '  = av_gracia,


   'CUMPLIMIENTO ' = (select valor from cobis..cl_catalogo where tabla = @w_tabla and codigo = av_estado),

   ' '             = av_estado


   from cr_acuerdo_vencimiento inner join cr_acuerdo on ac_acuerdo = av_acuerdo


   where ac_banco = @i_banco


   and   ac_tacuerdo = @i_tipo_acuerdo


   and   ac_fecha_proy = av_fecha


   and   ac_estado <> 'A'


   order by av_fecha


end








-- INGRESO DEL ACUERDO


if @i_modo = 'I'


begin


   -- VALIDA EXISTENCIA DE OPERACION


   select


   @w_fecha_ult_proceso = op_fecha_ult_proceso,


   @w_tipo_cobro        = op_tipo_cobro


   from cob_cartera..ca_operacion


   where op_banco = @i_banco





   if @@rowcount = 0


   begin


      select @w_error = 701013


      goto ERROR


   end





   -- VALIDA EXISTENCIA DE ACUERDO VIGENTE


   if exists(


   select 1 from cr_acuerdo


   where ac_banco  = @i_banco


   and   ac_estado = 'V'


   and   ac_fecha_proy = @i_fecha_pry)


   begin


      select @w_error = 2108044


      goto ERROR


   end





   -- VALIDA ENVIO DE USUARIO


   if @s_user is null


   begin


      select @w_error = 151005


      goto ERROR


   end





   -- VALIDA EXISTENCIA DEL TIPO DE ACUERDO


   if not exists (


   select 1


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_tipo_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @i_tipo_acuerdo


   and   C.estado = 'V' )


   begin


      select @w_error = 101000


      goto ERROR


   end





   -- VALIDA QUE FECHA DE PROYECCION SEA POSTERIOR A FECHA DE ULTIMO PROCESO


   if @i_fecha_pry <= @w_fecha_ult_proceso


   begin


      select @w_error = 101140


      goto ERROR


   end





   --VALIDA QUE AUN SE PUEDAN NEGOCIAR NUEVOS PAGOS


  if exists (select 1 from cr_acuerdo where ac_banco = @i_banco and ac_pago_cubierto = 'S' and ac_estado = 'V')

  begin


      select @w_error = 2108068


      goto ERROR


  end





   -- ESTADO DEFAULT DEL ACUERDO INGRESADO


   select @w_estado_ac = 'V'





   select @w_desc_estado_ac = C.valor


   from cobis..cl_tabla T, cobis..cl_catalogo C


   where T.tabla  = 'cr_estado_acuerdo'


   and   C.tabla  = T.codigo


   and   C.codigo = @w_estado_ac





   select @w_secuencial = ac_acuerdo


   from cr_acuerdo


   where ac_banco  = @i_banco


   and   ac_estado = 'V'


   and   ac_tacuerdo = @i_tipo_acuerdo





   --SI YA EXISTE EL ACUERDO, EL PREMIO SE ENVIA CON VALORES EN 0


   if @w_secuencial is not null


   begin


   select @i_cap_cond = 0,


          @i_int_cond = 0,


          @i_imo_cond = 0,


          @i_otr_cond = 0,


          @i_int_cond_pry = 0,


          @i_imo_cond_pry = 0,


          @i_otr_cond_pry = 0


   end








   -- DETERMINAR EL CODIGO DEL ACUERDO


   if @w_secuencial is null


   begin


   exec @w_error = cobis..sp_cseqnos


   @t_debug     = @t_debug,


   @t_file      = @t_file,


   @t_from      = @w_sp_name,


   @i_tabla     = 'cr_acuerdo',


   @o_siguiente = @w_secuencial out





   if @w_secuencial is null


      goto ERROR


   end





   insert into cr_acuerdo(


   ac_acuerdo             ,   ac_tacuerdo            ,   ac_banco               ,


   ac_producto            ,   ac_usr_ingreso         ,   ac_fecha_ingreso       ,


   ac_fecha_proy          ,   ac_cuotas_vencidas     ,   ac_dias_mora           ,


   ac_saldo_cap           ,   ac_saldo_int           ,   ac_saldo_imo           ,


   ac_saldo_honabo        ,   ac_saldo_ivahonabo     ,   ac_saldo_otros         ,


   ac_saldo_int_pry       ,   ac_saldo_imo_pry       ,   ac_saldo_honabo_pry    ,


   ac_saldo_ivahonabo_pry ,   ac_saldo_otros_pry     ,   ac_cap_cond            ,


   ac_int_cond            ,   ac_imo_cond            ,   ac_otr_cond            ,


   ac_int_cond_pry        ,   ac_imo_cond_pry        ,   ac_otr_cond_pry        ,


   ac_porc_cond_cap       ,   ac_porc_cond_int       ,   ac_porc_cond_imo       ,


   ac_porc_cond_otr       ,   ac_max_dias_ac         ,   ac_tipo_cobro_org      ,


   ac_estado              ,   ac_pago_cubierto


   )


   values(


   @w_secuencial          ,   @i_tipo_acuerdo        ,   @i_banco               ,


   @i_producto            ,   @s_user                ,   @w_fecha_ult_proceso   ,


   @i_fecha_pry           ,   @i_cuotas_ven          ,   @i_dias_mora           ,


   @i_saldo_cap           ,   @i_saldo_int           ,   @i_saldo_imo           ,


   @i_saldo_honabo        ,   @i_saldo_ivahonabo     ,   @i_saldo_otros         ,


   @i_saldo_int_pry       ,   @i_saldo_imo_pry       ,   @i_saldo_honabo_pry    ,


   @i_saldo_ivahonabo_pry ,   @i_saldo_otros_pry     ,   @i_cap_cond            ,


   @i_int_cond            ,   @i_imo_cond            ,   @i_otr_cond            ,


   @i_int_cond_pry        ,   @i_imo_cond_pry        ,   @i_otr_cond_pry        ,


   @i_porc_cond_cap       ,   @i_porc_cond_int       ,   @i_porc_cond_imo       ,


   @i_porc_cond_otr       ,   @i_max_dias_ac         ,   @w_tipo_cobro          ,


   @w_estado_ac           ,   @i_pago_cubierto


   )





   if @@error <> 0


   begin


      select @w_error = 2103055


      goto ERROR


   end





   if @i_tipo_acuerdo = 'P'


   begin





      -- CUANDO ES ACUERDO DE PRECANCELACION SE CAMBIA


      -- LA MODALIDAD DE APLICACION DE LOS PAGOS A ACUMULADO


      update cob_cartera..ca_operacion


      set op_tipo_cobro = 'A'


      where op_banco = @i_banco





      if @@error <> 0


      begin


         print 'ERROR AL MODIFICAR TIPO DE COBRO'


         select @w_error = 705007


         goto ERROR


      end


   end





   select @o_acuerdo = @w_secuencial





   select


   @w_secuencial,


   @w_estado_ac,


   @w_desc_estado_ac,


   convert(varchar(10), @w_fecha_ult_proceso, @i_formato_fecha)


end





if @i_modo = 'T' begin


   if @i_borrar_tmp = 'F'


   begin


      delete cr_acuerdo_vencimiento_tmp


      where av_usuario = @i_user


      and   av_sesion  = @i_ssn





      return 0


   end





   if @i_borrar_tmp = 'I'


   begin


      if isnull(@s_ssn, 0) = 0


      begin


         select @w_error = 141037


         goto ERROR


      end





      delete cr_acuerdo_vencimiento_tmp


      where av_usuario = @i_user


      and   av_sesion  = @s_ssn





      select @i_ssn = @s_ssn





      select @s_ssn


   end





   /*if @i_fecha not between isnull(@i_fecha_ult_proc, '12/31/2999') and isnull(@i_fecha_pry, '01/01/1900')

   begin


      select @w_error = 101140


      goto ERROR


  end*/





   if isnull(@i_monto, 0) <= 0


   begin


      select @w_error = 141011


      goto ERROR


   end





   select @i_gracia = isnull(@i_gracia, 0)


   --print 'cr_acuerdo.sp @i_gracia ' + cast(@i_gracia as varchar)





   if @i_gracia > 0 begin





      select


      @w_oficina  = op_oficina


      from cob_cartera..ca_operacion


      where op_banco = @i_banco





      -- DETERMINAR DIAS DE GRACIA PARA NO COBRAR MORA EN FERIADOS


      select @w_ciudad  = of_ciudad


      from   cobis..cl_oficina with (nolock)


      where  of_oficina = @w_oficina





      select @w_fecha_vencimiento = dateadd(dd, @i_gracia, @i_fecha)





      exec @w_return = cob_cartera..sp_dia_habil


      @i_fecha  = @w_fecha_vencimiento,


      @i_ciudad = @w_ciudad,


      @i_real   = 'S',


      @o_fecha  = @w_siguiente_dia out





      select @i_gracia = datediff(dd,@i_fecha,@w_siguiente_dia)





      print 'Fecha de Acuerdo mas Dias de Gracia quedan en dia festivo, se buscara dias de Gracia para ubicar siguiente dia habil'




   end





   insert into cr_acuerdo_vencimiento_tmp(


   av_usuario,     av_sesion,     av_acuerdo,


   av_fecha,       av_monto,      av_hono,


   av_neto,        av_gracia,     av_estado)


   values(


   @i_user,        @i_ssn,        @i_acuerdo,


   @i_fecha,       @i_abono,      @i_honoiva,


   @i_monto,       @i_gracia,     @i_estado)





   if @@error <> 0


   begin


      select @w_error = 2108040


      goto ERROR


   end


end





if @i_modo = 'V'


begin


   if @i_cambio_plan_pago = 'S' begin


      -- REGISTRO HISTORICO ACUERDO VENCMIENTOS


      insert into cr_acuerdo_vencimiento_his(


      av_acuerdo,       av_fecha,         av_monto,


      av_gracia,        av_estado,        av_fecha_estado,


      av_usario,        av_oficina,       av_fecha_mod,


      av_hora )


      select


      av_acuerdo,       av_fecha,         av_monto,


      av_gracia,        av_estado,        av_fecha_estado,


      @s_user,          @s_ofi,           @s_date,


      getdate()


      from   cr_acuerdo_vencimiento


      where  av_acuerdo = @i_acuerdo





      if @@error <> 0 begin


         select @w_error = 2108040


         goto ERROR


      end





      delete cr_acuerdo_vencimiento where  av_acuerdo = @i_acuerdo and av_estado  = 'PV'





      delete cr_acuerdo where ac_acuerdo = @i_acuerdo and ac_fecha_proy not in (select av_fecha from cr_acuerdo_vencimiento_tmp where av_acuerdo =
@i_acuerdo)

   end








   insert into cr_acuerdo_vencimiento(


   av_acuerdo,      av_fecha,       av_monto,


   av_hono,         av_neto,        av_gracia,


   av_estado)


   select


   av_acuerdo,      av_fecha,       av_monto,


   av_hono,         av_neto,        av_gracia,


   av_estado


   from cr_acuerdo_vencimiento_tmp


   where av_usuario = @i_user


   and   av_sesion  = @i_ssn


   and   av_acuerdo = @i_acuerdo





   if @@error <> 0


   begin


      select @w_error = 2108040


      goto ERROR


   end


end





-- NYM 89


if @i_modo = 'H' begin





   -- RETORNAMOS DATOS PRINCIPALES DEL ACUERDO


   select


   ac_acuerdo,


   convert(varchar(10),ac_fecha_ingreso,103),


   (select valor


    from cobis..cl_tabla T, cobis..cl_catalogo C


    where T.codigo = C.tabla


    and   T.tabla  = 'cr_tipo_acuerdo'


    and   C.codigo = A.ac_tacuerdo    ),


   (select of_nombre


    from cobis..cl_oficina


    where of_oficina = C.op_oficina),


   isnull(ac_saldo_cap,0) + isnull(ac_saldo_int,0) + isnull(ac_saldo_imo,0) + isnull(ac_saldo_honabo,0) + isnull(ac_saldo_ivahonabo,0) + isnull
(ac_saldo_otros,0),

   ac_cuotas_vencidas,


   (select case


           when en_subtipo ='C' then en_nomlar


           else en_nombre + + ' ' + p_p_apellido + ' '+ p_s_apellido


           end


    from cobis..cl_ente


    where en_ente = C.op_cliente),


   (select  en_ced_ruc


    from cobis..cl_ente


    where en_ente = C.op_cliente),


   (select ci_descripcion


    from cobis..cl_ente, cobis..cl_ciudad


    where en_ente     = C.op_cliente


    and   p_lugar_doc = ci_ciudad         ),


   (select sum(av_monto)


    from cob_credito..cr_acuerdo_vencimiento


    where A.ac_acuerdo = av_acuerdo         ),


   op_banco,


   (select en_tipo_ced


    from cobis..cl_ente


    where en_ente = C.op_cliente),


   (select  fu_nombre


    from cobis..cl_funcionario


    where fu_oficina = C.op_oficina


    and   fu_cargo  in (select C.codigo


                        from cobis..cl_catalogo C, cobis..cl_tabla T


                        where T.tabla  = 'cl_cargo'


                        and   T.codigo = C.tabla


                        and   C.valor  = 'DIRECTOR DE OFICINA'       )


    and   fu_estado  = 'V'                                            ),


   op_oficina


   from cob_credito..cr_acuerdo A,


        cob_cartera..ca_operacion C


   where op_banco      = ac_banco


   and   ac_acuerdo    = @i_acuerdo


   and   ac_fecha_proy = (Select min(ac_fecha_proy) from cob_credito..cr_acuerdo where ac_acuerdo = @i_acuerdo and ac_estado = 'V')




   -- RETORNAMOS VALOR DE CUOTAS CON SUS RESPECTIVAS FECHAS


   select


   convert(varchar(10), av_fecha, 103),


   av_monto


   from   cob_credito..cr_acuerdo_vencimiento


   where av_acuerdo = @i_acuerdo


   order by av_fecha








   select @w_monto = sum(av_monto)


   from   cob_credito..cr_acuerdo_vencimiento


   where  av_acuerdo = @i_acuerdo



/*

   exec @w_return = cob_sbancarios..sp_numeros_letras


   @t_trn      = 29322,


   @i_dinero   = @w_monto,


   @i_idioma   = 'E',


   @i_moneda   = 0,


   @o_texto    = @w_monto_letras
*/





   if @w_return <> 0 begin


      select @w_error = 2902786


      goto ERROR


   end





   select @w_monto_letras


end





if @i_modo = 'U' begin


   -- VALIDAR SI EL ESTADO ES DIFERENTE QUIERE DECIR QUE SE VA A ANULAR UN VIGENTE


   -- POR TANTO SE DEBE GARANTIZAR  QUE NO TENGA PREMIOS NI PAGOS APLICADOS





   select


   @w_ac_estado           = ac_estado,


   @w_ac_banco            = ac_banco,


   @w_ac_fecha_ingreso    = ac_fecha_ingreso,


   @w_ac_secuencial_rpa   = ac_secuencial_rpa,


   @w_tipo_acuerdo        = ac_tacuerdo,


   @w_tipo_cobro          = ac_tipo_cobro_org


   from cob_credito..cr_acuerdo


   where ac_acuerdo = @i_acuerdo





   if @@rowcount <= 0 begin


      select @w_error = 2108033


      goto ERROR


   end





   -- SOLO SE PUEDE MODIFICAR UN ACUERDO VIGENTE


   if @w_ac_estado <> 'V' begin


      select @w_error = 2108035


      goto ERROR


   end





   -- VALIDAMOS QUE LA FECHA DE ULTIMO PROCESO SEA IGUAL A LA FECHA DE INGRESO DE ACUERDO


   select @w_op_fecha_ult_proceso = op_fecha_ult_proceso


   from cob_cartera..ca_operacion


   where op_banco = @w_ac_banco





   if @@rowcount <= 0 begin


      select @w_error = 701013


      goto ERROR


   end








   if @i_estado_ac in ('A', 'I') begin





      if @w_op_fecha_ult_proceso <> @w_ac_fecha_ingreso and @i_estado_ac = 'A'


      begin


         select @w_error = 2108036


         goto ERROR


      end





      begin tran





      -- REGISTRO HISTORICO DE ACUERDO


      insert into cob_credito..cr_acuerdo_his(


      ac_acuerdo,            ac_tacuerdo,            ac_banco,


      ac_producto,           ac_usr_ingreso,         ac_fecha_ingreso,


      ac_usr_modif,          ac_fecha_modif,         ac_fecha_proy,


      ac_cuotas_vencidas,    ac_dias_mora,           ac_saldo_cap,


      ac_saldo_int,          ac_saldo_imo,           ac_saldo_honabo,


      ac_saldo_ivahonabo,    ac_saldo_otros,         ac_saldo_int_pry,


      ac_saldo_imo_pry,      ac_saldo_honabo_pry,    ac_saldo_ivahonabo_pry,


      ac_saldo_otros_pry,    ac_secuencial_rpa,      ac_cap_cond,


      ac_int_cond,           ac_imo_cond,            ac_otr_cond,


      ac_int_cond_pry,       ac_imo_cond_pry,        ac_otr_cond_pry,


      ac_porc_cond_cap,      ac_porc_cond_int,       ac_porc_cond_imo,


      ac_porc_cond_otr,      ac_max_dias_ac,         ac_tipo_cobro_org,


      ac_estado,             ac_usario,              ac_oficina,


      ac_fecha_mod,          ac_hora      )


      select


      ac_acuerdo,            ac_tacuerdo,            ac_banco,


      ac_producto,           ac_usr_ingreso,         ac_fecha_ingreso,


      ac_usr_modif,          ac_fecha_modif,         ac_fecha_proy,


      ac_cuotas_vencidas,    ac_dias_mora,           ac_saldo_cap,


      ac_saldo_int,          ac_saldo_imo,           ac_saldo_honabo,


      ac_saldo_ivahonabo,    ac_saldo_otros,         ac_saldo_int_pry,


      ac_saldo_imo_pry,      ac_saldo_honabo_pry,    ac_saldo_ivahonabo_pry,


      ac_saldo_otros_pry,    ac_secuencial_rpa,      ac_cap_cond,


      ac_int_cond,           ac_imo_cond,            ac_otr_cond,


      ac_int_cond_pry,       ac_imo_cond_pry,        ac_otr_cond_pry,


      ac_porc_cond_cap,      ac_porc_cond_int,       ac_porc_cond_imo,


      ac_porc_cond_otr,      ac_max_dias_ac,         ac_tipo_cobro_org,


      ac_estado,             @s_user,                @s_ofi,


      @s_date,               getdate()


      from cob_credito..cr_acuerdo


      where  ac_acuerdo = @i_acuerdo





      if @@error <> 0 begin


         select @w_error = 2108038


         goto ERROR


      end





      -- Actualizamos estado  y Acutalizamos premio


      update cr_acuerdo set


      ac_estado = @i_estado_ac


      where ac_acuerdo = @i_acuerdo





      if @@error <> 0 begin


         select @w_error = 2108039


         goto ERROR


      end





      commit tran





      return 0





   end





   begin tran





   -- VALIDAMOS QUE NO TENGA APLICADO PREMIO


   if @i_cambio_regalo = 'S' begin





      if @w_ac_secuencial_rpa > 0 begin


         select @w_error = 2108037


         goto ERROR


      end





      -- REGISTRO HISTORICO DE ACUERDO


      insert into cob_credito..cr_acuerdo_his(


      ac_acuerdo,            ac_tacuerdo,            ac_banco,


      ac_producto,           ac_usr_ingreso,         ac_fecha_ingreso,


      ac_usr_modif,          ac_fecha_modif,         ac_fecha_proy,


      ac_cuotas_vencidas,    ac_dias_mora,           ac_saldo_cap,


      ac_saldo_int,          ac_saldo_imo,           ac_saldo_honabo,


      ac_saldo_ivahonabo,    ac_saldo_otros,         ac_saldo_int_pry,


      ac_saldo_imo_pry,      ac_saldo_honabo_pry,    ac_saldo_ivahonabo_pry,


      ac_saldo_otros_pry,    ac_secuencial_rpa,      ac_cap_cond,


      ac_int_cond,           ac_imo_cond,            ac_otr_cond,


      ac_int_cond_pry,       ac_imo_cond_pry,        ac_otr_cond_pry,


      ac_porc_cond_cap,      ac_porc_cond_int,       ac_porc_cond_imo,


      ac_porc_cond_otr,      ac_max_dias_ac,         ac_tipo_cobro_org,


      ac_estado,             ac_usario,              ac_oficina,


      ac_fecha_mod,          ac_hora      )


      select


      ac_acuerdo,            ac_tacuerdo,            ac_banco,


      ac_producto,           ac_usr_ingreso,         ac_fecha_ingreso,


      ac_usr_modif,          ac_fecha_modif,         ac_fecha_proy,


      ac_cuotas_vencidas,    ac_dias_mora,           ac_saldo_cap,


      ac_saldo_int,          ac_saldo_imo,           ac_saldo_honabo,


      ac_saldo_ivahonabo,    ac_saldo_otros,         ac_saldo_int_pry,


      ac_saldo_imo_pry,      ac_saldo_honabo_pry,    ac_saldo_ivahonabo_pry,


      ac_saldo_otros_pry,    ac_secuencial_rpa,      ac_cap_cond,


      ac_int_cond,           ac_imo_cond,            ac_otr_cond,


      ac_int_cond_pry,       ac_imo_cond_pry, ac_otr_cond_pry,


      ac_porc_cond_cap,      ac_porc_cond_int,       ac_porc_cond_imo,


      ac_porc_cond_otr,      ac_max_dias_ac,         ac_tipo_cobro_org,


      ac_estado,             @s_user,                @s_ofi,


      @s_date,               getdate()


      from cob_credito..cr_acuerdo


      where  ac_acuerdo = @i_acuerdo





      if @@error <> 0 begin


         select @w_error = 2108038


         goto ERROR


      end





      -- ACTUALIZAMOS ESTADO  Y ACUTALIZAMOS PREMIO

      select @w_min_ac_fecha_proy = min(ac_fecha_proy) from cr_acuerdo where ac_acuerdo = @i_acuerdo

      update cr_acuerdo set


      ac_cap_cond = @i_cap_cond,


      ac_int_cond = @i_int_cond,


      ac_imo_cond = @i_imo_cond,


      ac_otr_cond = @i_otr_cond


      where ac_acuerdo = @i_acuerdo


      --and   ac_fecha_proy = (select min(ac_fecha_proy) from cr_acuerdo where ac_acuerdo = @i_acuerdo)  --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
      and   ac_fecha_proy = @w_min_ac_fecha_proy  --LPO CDIG MySql no soporta abrir la misma tabla en una misma sentencia
      


      if @@error <> 0 begin


         select @w_error = 2108039


         goto ERROR


      end





   end





   if @i_cambio_plan_pago = 'S'


   begin


      exec @w_return = sp_acuerdo


      @t_trn              = 22273,


      @s_ssn              = @s_ssn,


      @s_user             = @s_user,


      @s_ofi              = @s_ofi,


      @s_date             = @s_date,


      @t_debug            = @t_debug,


      @t_file             = @t_file,


      @i_modo             = 'V',


      @i_user             = @s_user,


      @i_ssn              = @i_ssn,


      @i_acuerdo          = @i_acuerdo,


      @i_cambio_plan_pago = 'S'





      if @@error <> 0 begin


         select @w_error = 708201


         goto ERROR


      end





      exec @w_return = sp_acuerdo


      @t_trn         = 22273,


      @s_ssn         = @s_ssn,


      @s_user        = @s_user,


      @s_ofi         = @s_ofi,


      @s_date        = @s_date,


      @t_debug       = @t_debug,


      @t_file        = @t_file,


      @i_ssn         = @i_ssn,


      @i_user        = @s_user,


      @i_modo        = 'T',


      @i_borrar_tmp  = 'F'





      if @@error <> 0 begin


         select @w_error = 708201


         goto ERROR


      end


   end





   commit tran


end  -- modo U





return 0





ERROR:





exec cobis..sp_cerror


@t_debug  = @t_debug,


@t_file   = @t_file,


@t_from   = @w_sp_name,
@i_num    = @w_error





return @w_error




GO
