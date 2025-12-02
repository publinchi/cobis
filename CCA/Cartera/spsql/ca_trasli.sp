/*ca_trasli.sp******************************************************/
/*  Archivo:                ca_trasli.sp                           */
/*  Stored procedure:       sp_traslado_linea_emp                  */
/*  Base de Datos:          cob_cartera                            */
/*  Producto:               Credito                                */
/*  Disenado por:           Xavier Maldonado                       */
/*  Fecha de Documentacion: Sep/2010                               */
/*******************************************************************/
/*          IMPORTANTE                                             */
/*  Este programa es parte de los paquetes bancarios propiedad de  */
/*  'MACOSA',representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como     */
/*  cualquier autorizacion o agregado hecho por alguno de sus      */
/*  usuario sin el debido consentimiento por escrito de la         */
/*  Presidencia Ejecutiva de MACOSA o su representante             */
/*******************************************************************/
/*          PROPOSITO                                              */
/*  Este stored procedure permite realizar las siguientes          */ 
/*  operaciones  en la tabla ca_traslado_linea                     */
/*  Insert, Update, Delete                                         */
/*  Query, All, Value, Search                                      */
/*                                                                 */
/*******************************************************************/
/*          MODIFICACIONES                                         */
/*  FECHA       AUTOR             RAZON                            */
/*  Feb/2011    Alfredo Zuluaga  Emision Inicial                   */
/*  Mar/2014    Liana Coto       Req 406. Seguro Deudores Empleados*/
/*******************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_linea_emp')
    drop proc sp_traslado_linea_emp
go
---ORS 751 ENE.15.2014
create proc sp_traslado_linea_emp (
@s_ssn                   int           = null,
@s_date                  datetime      = null,
@s_user                  login         = null,
@s_term                  descripcion   = null,
@s_ofi                   smallint      = null,
@s_srv                   varchar(30)   = null,
@s_lsrv                  varchar(30)   = null,
@t_rty                   char(1)       = null,
@t_trn                   smallint      = null,
@t_debug                 char(1)       = 'N',
@t_file                  varchar(14)   = null,
@t_from                  varchar(30)   = null,
@i_operacion             char(1)       = null,
@i_banco                 varchar(24)   = null,
@i_tl_operacion          int           = null,
@i_tl_fecha_traslado     datetime      = null,
@i_tl_linea_origen       varchar(10)   = null,
@i_tl_linea_destino      varchar(10)   = null,
@i_tl_usuario            varchar(14)   = null,
@i_tl_comentario         varchar(255)  = null,
@i_tl_estado             varchar(1)    = null,
@i_tl_sec_transaccion    int           = null,
@i_formato_fecha         int           = null

)
as
declare
@w_today                 datetime,     /* FECHA DEL DIA */ 
@w_return                int,          /* VALOR QUE RETORNA  */
@w_sp_name               varchar(32),  /* NOMBRE STORED PROC */
@w_existe                int,
@w_tl_operacion          int,
@w_tl_fecha_traslado     datetime,
@w_tl_linea_origen       varchar(10),
@w_tl_linea_destino      varchar(10),
@w_tl_usuario            varchar(14),
@w_tl_comentario         varchar(255),
@w_tl_estado             varchar(1),
@w_tl_sec_transaccion    int,
@w_fecha_proceso         datetime,
@w_secuencial_pag        int,
@w_msg                   varchar(255),
@w_entidad_convenio      varchar(10),
@w_bancamia              int

   
select @w_today      = @s_date
select @w_sp_name    = 'sp_traslado_linea_emp'
select @i_tl_usuario = @s_user


/* Codigos de Transacciones     */
/********************************/

if (@t_trn <> 7979 and @i_operacion = 'I') or   
   (@t_trn <> 7979 and @i_operacion = 'U') or   
   (@t_trn <> 7978 and @i_operacion = 'D') or   
   (@t_trn <> 7977 and @i_operacion = 'S') or   
   (@t_trn <> 7979 and @i_operacion = 'T')
begin
    /* TIPO DE TRANSACCION NO CORRESPONDE */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1 
end


--codigo de ente asignado al Banco 
select @w_bancamia  = convert(varchar(24),pa_int)
from cobis..cl_parametro
where pa_nemonico = 'CCBA'
and   pa_producto = 'CTE'

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

select 
@i_tl_operacion = op_operacion
from cob_cartera..ca_operacion
where op_banco = @i_banco

   
/* CHEQUEO DE EXISTENCIAS */
/**************************/
if @i_operacion <> 'S' begin
   select
   @w_tl_operacion       = tl_operacion,
   @w_tl_fecha_traslado  = tl_fecha_traslado,
   @w_tl_linea_origen    = tl_linea_origen,
   @w_tl_linea_destino   = tl_linea_destino,
   @w_tl_usuario         = tl_usuario,
   @w_tl_comentario      = tl_comentario,
   @w_tl_estado          = tl_estado,
   @w_tl_sec_transaccion = tl_sec_transaccion
   from  ca_traslado_linea
   where tl_operacion = @i_tl_operacion

   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0

   select 
   @w_entidad_convenio = op_entidad_convenio
   from ca_operacion
   where op_operacion = @i_tl_operacion

   if convert(int,isnull(@w_entidad_convenio,0)) <> @w_bancamia 
   begin
      select @w_msg = 'No puede Actualizar Cambio de Linea porque No es Empleado '

      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_msg   = @w_msg,
      @i_num   = 2105001
      return 1 
   end

end
   

/* INSERCION DEL REGISTRO */
/**************************/

if @i_operacion = 'I' begin

   if @w_existe = 1 begin
      /* REGISTRO YA EXISTE */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 2101002
       return 1 
   end
   
   begin tran

     select @i_tl_estado          = 'I'
     select @w_tl_sec_transaccion = isnull(@w_tl_sec_transaccion, 0)

     insert into ca_traslado_linea(
     tl_operacion,         tl_fecha_traslado,      tl_linea_origen,
     tl_linea_destino,     tl_usuario,             tl_comentario,
     tl_estado,            tl_sec_transaccion
     )
     values (
     @i_tl_operacion,      @i_tl_fecha_traslado,   @i_tl_linea_origen,
     @i_tl_linea_destino,  @i_tl_usuario,          @i_tl_comentario,
     @i_tl_estado,         @w_tl_sec_transaccion
     )
         
     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        return 1 
     end
   
   commit tran

end

/* ACTUALIZACION DEL REGISTRO */
/******************************/

if @i_operacion = 'U' begin

   if @w_existe = 0 begin
       /* REGISTRO A ACTUALIZAR NO EXISTE */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 2105002
       return 1 
   end

   if @w_tl_estado = 'P' begin

      select @w_msg = 'No puede Actualizar Cambio de Linea porque ya esta en estado Procesado '

      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_msg   = @w_msg,
      @i_num   = 2105001
      return 1 
   end
      
   begin tran
   
   update ca_traslado_linea set  
   tl_linea_destino  = @i_tl_linea_destino,
   tl_comentario     = @i_tl_comentario,
   tl_fecha_traslado = @i_tl_fecha_traslado
   where tl_operacion = @i_tl_operacion
   and   tl_estado    = 'I'

   if @@error <> 0 begin
      /* ERROR EN ACTUALIZACION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2105001
      return 1 
   end

   commit tran
            
end



/* ELIMINACION DE REGISTROS */
/****************************/
if @i_operacion = 'D' begin

   if @w_existe = 0 begin
       /* REGISTRO A ACTUALIZAR NO EXISTE */
       select @w_msg = 'No Existe Registro a Eliminar '

       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_msg   = @w_msg,
       @i_num   = 2105002
       return 1 
   end

   if @w_tl_estado = 'P' begin

      select @w_msg = 'No puede Eliminar Cambio de Linea porque ya esta en estado Procesado '

      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_msg   = @w_msg,
      @i_num   = 2107001
      return 1 
   end

   delete ca_traslado_linea
   where tl_operacion = @i_tl_operacion
   and   tl_estado    = 'I'
                     
   if @@error <> 0 begin
      /* ERROR EN ELIMINACION DE REGISTRO */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 2107001
       return 1 
   end            
end

                      

/**** SEARCH ****/
/****************/
if @i_operacion = 'S' begin

   select    
   operacion  = op_operacion,
   fecha_tras = convert(varchar(10),''),
   linea_ori  = op_toperacion,
   linea_des  = convert(varchar(10), ''),
   usuario    = convert(varchar(10), ''),
   comenta    = convert(varchar(255), ''),
   estado     = convert(varchar(1), ''),
   des_estado = convert(varchar(15), ''),
   secuencial = convert(int,0),
   banco      = op_banco,
   oficina    = op_oficina,
   toperacion = op_toperacion,
   clase      = op_clase,
   tipo       = op_tipo,
   tipo_linea = op_tipo_linea,
   subtipo    = op_subtipo_linea,
   cliente    = op_cliente,
   empleado   = case when convert(int,isnull(@w_entidad_convenio,0)) <> @w_bancamia then 'NO' else 'SI' end,
   nombre     = op_nombre,
   estado_car = op_estado,
   monto      = op_monto   
   into #temporal
   from cob_cartera..ca_operacion
   where op_operacion = @i_tl_operacion
   
   update #temporal set
   fecha_tras = convert(varchar(10), tl_fecha_traslado, @i_formato_fecha),
   linea_ori  = tl_linea_origen,
   linea_des  = tl_linea_destino,
   usuario    = tl_usuario,
   comenta    = tl_comentario,
   estado     = tl_estado,
   des_estado = case when tl_estado = 'I' then 'INGRESADO' else 'PROCESADO' end,
   secuencial = tl_sec_transaccion
   from ca_traslado_linea
   where tl_operacion = operacion
      
   if @@rowcount > 0 begin
   
      select 
      'Numero Operacion' = operacion,
      'Fecha Traslado'   = fecha_tras,
      'Linea Origen'     = linea_ori,
      'Linea Destino'    = linea_des,
      'Usuario'          = usuario,
      'Comentario'       = comenta,
      'Estado'           = estado,
      'Desc. Estado'     = des_estado,
      'Sec. Transaccion' = secuencial,
      'Banco'            = banco,
      'Oficina'          = oficina,
      'Tipo Operacion'   = toperacion,
      'Clase Cartera'    = clase,
      'Tipo'             = tipo,
      'Tipo Linea'       = tipo_linea,
      'SubTipo Linea'    = subtipo,
      'Cliente'          = cliente,
      'Empleado'         = empleado,
      'Nombre Cliente'   = nombre,
      'Estado Cartera'   = estado_car,
      'Monto Op.'        = monto
      from #temporal
   end  
end
                         


/* REALIZAR EL TRASLADO DE LA LINEA */
/************************************/

if @i_operacion = 'T' begin

   if @w_tl_estado = 'P' begin
      select @w_msg = 'No puede Realizar el Cambio de Linea porque ya esta en estado Procesado '

      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_msg   = @w_msg,
      @i_num   = 2107001
      return 1 
   end

   exec @w_secuencial_pag = sp_gen_sec
   @i_operacion = @w_tl_operacion

   begin tran

   exec @w_return    = sp_historial
	@i_operacionca    = @w_tl_operacion,
	@i_secuencial     = @w_secuencial_pag
	if @w_return <> 0 
      begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = @w_return
        return 1 
     end
	   
   
     insert into ca_transaccion with (rowlock)(
     tr_fecha_mov,         tr_toperacion,       tr_moneda,
     tr_operacion,         tr_tran,             tr_secuencial,
     tr_en_linea,          tr_banco,            tr_dias_calc,
     tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
     tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
     tr_estado,            tr_gerente,          tr_gar_admisible,
     tr_reestructuracion,  tr_calificacion,     tr_observacion,
     tr_fecha_cont,        tr_comprobante
     )
     select
     @w_fecha_proceso,     @w_tl_linea_origen,          op_moneda,
     op_operacion,         'TLI',                       @w_secuencial_pag,
     'S',                  op_banco,                    0, 
     op_oficina,           op_oficina,                  @s_user,
     @s_term,              @w_fecha_proceso,            0,
     'ING',                op_oficial,                  op_gar_admisible,
     op_reestructuracion,  isnull(op_calificacion,'A'), 'TRASLADO DE LINEA ',
     @s_date,              0
     from ca_operacion
     where op_operacion = @w_tl_operacion

     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        return 1 
     end

     --Valores de la Cuenta Origen (Empleado)
     insert into ca_det_trn (
     dtr_secuencial,     dtr_operacion,    dtr_dividendo,
     dtr_concepto,       dtr_estado,       dtr_periodo,
     dtr_codvalor,       dtr_monto,        dtr_monto_mn,
     dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
     dtr_afectacion,     dtr_cuenta,       dtr_beneficiario,
     dtr_monto_cont
     )
     select                                                                                                            
     @w_secuencial_pag,  @w_tl_operacion,  am_dividendo,
     am_concepto,        case am_estado when 0 then op_estado else am_estado end, 0,
     co_codigo * 1000 + case am_estado when 0 then op_estado else am_estado end * 10,
     -1 * sum(am_acumulado - am_pagado),  0,
     op_moneda,          1,               'N',
     'D',                '1',             '',
     0
     from ca_amortizacion, ca_concepto, ca_operacion
     where am_operacion = @w_tl_operacion
     and   am_estado   <> 3
     and   co_concepto  = am_concepto
     and   am_operacion = op_operacion
     group by am_dividendo, am_concepto, case am_estado when 0 then op_estado else am_estado end,
              co_codigo * 1000 + case am_estado when 0 then op_estado else am_estado end * 10, op_moneda
     having sum(am_acumulado - am_pagado) > 0

     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        return 1 
     end

     --Valores de la Cuenta Origen (ExEmpleado)
     insert into ca_det_trn (
     dtr_secuencial,     dtr_operacion,    dtr_dividendo,
     dtr_concepto,       dtr_estado,       dtr_periodo,
     dtr_codvalor,       dtr_monto,        dtr_monto_mn,
     dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
     dtr_afectacion,     dtr_cuenta,       dtr_beneficiario,
     dtr_monto_cont
     )
     select                                                                                                            
     @w_secuencial_pag,  @w_tl_operacion,  am_dividendo,
     am_concepto,        case am_estado when 0 then op_estado else am_estado end, 0,
     co_codigo * 1000 + case am_estado when 0 then op_estado else am_estado end * 10, 
     sum(am_acumulado - am_pagado),  0,
     op_moneda,          1,               'N',
     'D',                '0',             '',
     0
     from ca_amortizacion, ca_concepto, ca_operacion
     where am_operacion = @w_tl_operacion
     and   am_estado   <> 3
     and   co_concepto  = am_concepto
     and   am_operacion = op_operacion
     group by am_dividendo, am_concepto, case am_estado when 0 then op_estado else am_estado end,
              co_codigo * 1000 + case am_estado when 0 then op_estado else am_estado end * 10, op_moneda
     having sum(am_acumulado - am_pagado) > 0

     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        return 1 
     end

     --/*** Req 406  27/MAR/2014 ***/
     exec @w_return           =  cob_cartera..sp_asigna_segdeuven
          @i_operacion        = @i_tl_operacion,
		    @i_tl_linea_destino = @i_tl_linea_destino

	  if @w_return <> 0
	  begin
	      /* ERROR EN INSERCION DE REGISTRO */
			exec cobis..sp_cerror
			@t_debug = @t_debug,
			@t_file  = @t_file, 
			@t_from  = @w_sp_name,
			@i_num   = @w_return
			 return 1 
     end

     update ca_traslado_linea set
     tl_estado          = 'P',
     tl_sec_transaccion = @w_secuencial_pag
     where tl_operacion = @w_tl_operacion
     and   tl_estado    = 'I'

     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2105001
        return 1 
     end

     update ca_operacion set
     op_entidad_convenio = null,
     op_toperacion       = @i_tl_linea_destino
     where op_operacion  = @w_tl_operacion

     if @@error <> 0  begin
        /* ERROR EN INSERCION DE REGISTRO */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2105001
        return 1 
     end

     print 'Traslado de Linea Exitoso' 

   commit tran

end

return 0
go

