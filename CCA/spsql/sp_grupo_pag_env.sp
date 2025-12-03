use cob_cartera
go
/************************************************************************/
/*      Archivo:                sp_grupo_pag_env.sp                     */
/*      Stored procedure:       sp_grupo_pag_env                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LGU                                     */
/*      Fecha de escritura:     Abr. 2017                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Determinar las operaciones grupales que vencen a la fecha       */
/*      para generar un archivo plano y enviarlo al banco               */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR             RAZON                         */
/* 19-Abr-2017          LGU          Emision inicial                    */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_grupo_pag_env')
    drop proc sp_grupo_pag_env
go

create proc sp_grupo_pag_env
-- parametros del bacth
   @i_param1           varchar(255)  = null, -- opcion
   @i_param2           varchar(255)  = null, -- fecha proceso
   @i_param3           varchar(255)  = null, -- nombre archivo
   @i_param4           varchar(255)  = null, -- entidad a la que se envia el archivo
-- parametros del bacth
   @i_opcion           char(10)      = null, -- I = Ingresar E = envio  R = recepcion A = aplicar
   @i_fecha_proceso    datetime      = null,
   @i_archivo          varchar(255)  = null
as
declare
   @w_return            int,
   @w_fecha_genera      datetime,
   @w_est_ing           char(1),
   @w_est_env           char(1),
   @w_est_rcp           char(1),
   @w_est_apl           char(1),
   @w_hora              char(6)

declare
   @w_path_sapp  varchar(200),
   @w_sapp       varchar(200),
   @w_path       varchar(200),
   @w_msg        varchar(200),
   @w_comando    varchar(2000),
   @w_bd         varchar(200),
   @w_tabla      varchar(200),
   @w_destino    varchar(200),
   @w_errores    varchar(200),
   @w_sep        varchar(1),
   @w_fecha_arch varchar(10)

select
   @w_est_ing = 'I',
   @w_est_env = 'E',
   @w_est_rcp = 'R',
   @w_est_apl = 'A'
select
   @i_opcion           = @i_param1,
   @i_fecha_proceso    = convert(datetime, @i_param2, 101),
   @i_archivo          = isnull(@i_param3, 'CBRPRESTGRUPAL'),
   @i_param4           = isnull(@i_param4, 'STD')

   if exists (select 1 from cobis..cl_dias_feriados where df_ciudad = 1 and df_fecha  = @i_fecha_proceso)
   begin
      print '     Atencion ... La fecha de Ejecucion de Orden de Debito no puede ser en feriado:  ' + convert(varchar, @i_fecha_proceso, 101)
      return 1
   end

   select @w_fecha_genera = @i_fecha_proceso

if @i_opcion = 'I' -- ingresa informacion
begin
   insert into ca_pago_grp_env (
          pe_fecha_proceso,
          pe_fecha_envio,         pe_banco,
          pe_valor_debitar,       pe_cuenta_expediente,
          pe_estado,              pe_operacion,
          pe_dividendo,           pe_fecha_ven,
          pe_cliente,             pe_grupo,
          pe_referencia_grupal,   pe_numero_cta_debito,
          pe_tipo_pago,           pe_entidad)
   select  -- PRESTAMOS  GRUPALES
          @i_fecha_proceso,
          @w_fecha_genera,           A.op_banco,
          0,                         null,
          @w_est_ing,                A.op_operacion,
          max(B.di_dividendo),       max(B.di_fecha_ven),
          A.op_cliente,              tg_grupo,
          max(tg_referencia_grupal), A.op_cuenta,
          'N',                       @i_param4
     from ca_operacion A , ca_dividendo B, ca_estado, cob_credito..cr_tramite_grupal
    where A.op_operacion >= 0
      and A.op_toperacion  IN (select c1.codigo from cobis..cl_tabla t1, cobis..cl_catalogo c1 where c1.tabla = t1.codigo
                               and t1.tabla in ( 'ca_grupal', 'ca_interciclo'))
      and A.op_estado     = es_codigo
      and es_acepta_pago  = 'S'
      and B.di_operacion  = A.op_operacion
      AND B.di_estado    <> 3
      AND B.di_fecha_ven <= @i_fecha_proceso
      and isnull(A.op_cuenta,'') <> ''
      and A.op_operacion   = tg_operacion
      and tg_operacion     = B.di_operacion
    group by A.op_banco, A.op_operacion, A.op_cliente, tg_grupo, A.op_cuenta
   UNION
   select  -- PRESTAMOS INDIVIDUALES
          @i_fecha_proceso,
          @w_fecha_genera,           A.op_banco,
          0,                         null,
          @w_est_ing,                A.op_operacion,
          max(B.di_dividendo),       max(B.di_fecha_ven),
          A.op_cliente,              null,
          null,                      A.op_cuenta,
          'N',                       @i_param4
     from ca_operacion A , ca_dividendo B, ca_estado
    where A.op_operacion >= 0
      and A.op_toperacion  NOT IN (select c1.codigo from cobis..cl_tabla t1, cobis..cl_catalogo c1 where c1.tabla = t1.codigo
                               and t1.tabla in ( 'ca_grupal', 'ca_interciclo'))
      and A.op_estado     = es_codigo
      and es_acepta_pago  = 'S'
      and B.di_operacion  = A.op_operacion
      AND B.di_estado    <> 3
      AND B.di_fecha_ven <= @i_fecha_proceso
      and isnull(A.op_cuenta,'') <> ''
    group by A.op_banco, A.op_operacion, A.op_cliente, A.op_cuenta


   update ca_pago_grp_env set
      pe_valor_debitar  = isnull((select isnull(sum(am_cuota-am_pagado+am_gracia),0)
                             from ca_amortizacion, ca_dividendo
                             where am_operacion = A.pe_operacion
                             and am_dividendo <= A.pe_dividendo
                             and di_operacion = am_operacion
                             and di_dividendo = am_dividendo
                             and di_estado    != 3),0)
    from ca_pago_grp_env A
   where A.pe_fecha_envio = @w_fecha_genera
     and A.pe_estado      = @w_est_ing

   if @@error <> 0
   begin
      print 'Error en actualizacion de registro'
      select @w_return = 201000
      return @w_return
   end

   update ca_pago_grp_env set
      pe_identificacion      = en_ced_ruc,
      pe_tipo_identificacion = en_tipo_ced
   from ca_pago_grp_env A, cobis..cl_ente
   where A.pe_cliente = en_ente
   and A.pe_estado    = @w_est_ing

   if @@error <> 0
   begin
      print 'Error en actualizacion de registro'
      select @w_return = 201000
      return @w_return
   end


   return 0
end


if @i_opcion = 'E' -- envia informacion
begin
   select @w_path_sapp = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'S_APP'

   if @w_path_sapp is null
   begin
      select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
      select @w_return = 724607
      goto ERROR
    end

   select @w_path  = pp_path_destino
   from cobis..ba_path_pro
   where pp_producto  = 7

   select @w_sapp      = @w_path_sapp + 's_app'

   select
      @w_bd       = 'cob_cartera',
      @w_tabla    = 'tmp_cadena',
      @w_sep      = '|' --char(9)  -- tabulador

   select @w_fecha_arch = convert(varchar, @i_fecha_proceso, 112)
   select @w_hora = substring(convert(varchar, getdate(), 108), 1,2)+
                    substring(convert(varchar, getdate(), 108), 4,2)+
                    substring(convert(varchar, getdate(), 108), 7,2)

   select
      @w_destino  = @i_archivo + '_' + @w_fecha_arch + '.txt',
      @w_errores  = @i_archivo + '_' + @w_fecha_arch + '_' + @w_hora + '.err'

   truncate table tmp_cadena

   insert into tmp_cadena
   select
                 convert(varchar,pe_fecha_envio,101) --- mm/dd/yyyy
      + @w_sep + convert(varchar,pe_fecha_envio,101) --- mm/dd/yyyy
      + @w_sep + (pe_tipo_pago)
      + @w_sep + pe_identificacion
      + @w_sep + pe_tipo_identificacion
      + @w_sep + pe_numero_cta_debito
      + @w_sep + isnull(pe_cuenta_expediente               ,'')
      + @w_sep + isnull(pe_referencia_grupal               ,'')
      + @w_sep + isnull(convert(varchar, pe_operacion )    ,'0')
      + @w_sep + isnull(pe_banco                           ,'N/A')
      + @w_sep + isnull(convert(varchar, pe_valor_debitar ),'0')
      + @w_sep + isnull(convert(varchar, pe_valor_debitado),'0')
      + @w_sep + '0'        -- ID de la TRANSACCION REALIZADA EN EL BANCO
      + @w_sep + @i_param4  -- CODIGO DE LA ENTIDAD QUE RECEPTA LOS PAGOS
      + @w_sep + isnull(@w_est_env                         ,'N/A')
   from cob_cartera..ca_pago_grp_env
   where pe_estado      = @w_est_ing
   and pe_fecha_proceso = @i_fecha_proceso

   select  @w_comando = @w_sapp + ' bcp -auto -login ' + @w_bd + '..' + @w_tabla + ' out ' + @w_path+@w_destino + ' -b5000 -c -e' + @w_path+@w_errores + ' -t"'+@w_sep + '" -config ' + @w_sapp + '.ini'

   print ' COMANDO = '+ @w_comando
   exec @w_return = xp_cmdshell @w_comando
   if @w_return <> 0 begin
      select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_return)
      goto ERROR
   end

   update cob_cartera..ca_pago_grp_env set
      pe_estado    = @w_est_env  -- enviado
   where pe_estado    = @w_est_ing
   and pe_fecha_envio = @w_fecha_genera

   return 0

ERROR:
   return @w_return
end

return 0

go


