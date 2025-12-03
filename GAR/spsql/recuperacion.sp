/*************************************************************************/
/*   Archivo:              recuperacion.sp                               */
/*   Stored procedure:     sp_recuperacion                               */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_recuperacion') IS NOT NULL
    DROP PROCEDURE dbo.sp_recuperacion
go
create proc sp_recuperacion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_rol                smallint    = NULL, --GCR
   @s_org                char(1)     = NULL, ---GCR
   @s_srv                varchar(30) = null, ---GCR
   @s_sesn               int = null, ---GCR
   @s_lsrv               varchar(30) = null, ---GCR
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_recuperacion       smallint  = null,   
   @i_valor              money  = null,
   @i_ret_iva            money  = 0, ---GCR
   @i_ret_fte            money  = 0, ---GCR
   @i_vencimiento        smallint  = null,
   @i_fecha              datetime  = null,
   @i_formato_fecha      int = null,
   @i_cobro_vencimiento	 money = null, 
   @i_cobro_mora         money = null, 
   @i_cobro_comision     money = null, 
   @i_producto           catalogo = null, ---GCR
   @i_moneda             tinyint = null, ---GCR
   @i_cuenta             varchar(24) = null, ---GCR
   @i_monto_mop          money = null, ---GCR
   @i_monto_mn           money = null, ---GCR
   @i_cotizacion_mpg     money = null, ---GCR
   @i_tcotizacion_mpg    char(1) = null, ---GCR
   @i_cotizacion_mop     money = null, ---GCR
   @i_tcotizacion_mop    char(1) = null ---GCR

)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_recuperacion       smallint,
   @w_valor              money,
   @w_valor_vencimiento  money,
   @w_vencimiento        smallint,
   @w_fecha              datetime,
   @w_ultimo             smallint,
   @w_error              int,
   @w_des_tipo           descripcion,
   @w_debcred            char(1),
   @w_descripcion        descripcion,
   @w_valor_comision     money,
   @w_valor_mora         money,
   @w_cobro_vencimiento  money,
   @w_cobro_mora         money,
   @w_cobro_comision     money,
   @w_valor_aux          money,
   @w_valor_absoluto     money,
   @w_dias_mora          smallint,
   @w_fecha_vencimiento  datetime,
   @w_status             int,
   @w_suma_ven           money,
   @w_suma_rec           money,
   @w_diferencia         money,
   @w_codigo_externo     varchar(64),
   @w_estado_gar         char(1),
   @w_beneficiario       varchar(64),
   @w_fecha_hoy          datetime, ---GCR
   @w_fecha_emision      datetime, ----GCR
   @w_fecha_tolerancia   datetime, ----GCR
   @w_deudor             int, ----GCR
   @w_cliente            int, ----GCR
   @w_documento          varchar(20), ----GCR
   @w_cancelado          char(1), ---GCR
   @w_ve_ret_iva         money, ---GCR
   @w_ve_ret_fte         money, ---GCR
   @w_ret_iva            money, ---GCR
   @w_ret_fte            money, ---GCR
   @w_tret_iva           money, ---GCR
   @w_tret_fte           money, ---GCR   
   @w_banco              varchar(24), ---GCR
   @w_operacion          int, ---GCR
   @w_moneda             tinyint, ---GCR
   @w_secuencial_ing     int, ---GCR
   @w_secuencial_pag     int, ---GCR
   @w_valor_trn          money, ---GCR
   @w_estado_op          tinyint,  ---GCR
   @w_est_credito        tinyint,  ---GCR
   @w_est_no_vigente     tinyint,  ---GCR
   @w_est_cancelado      tinyint,  ---GCR
   @w_est_anulado        tinyint,  ---GCR 
   @w_ejecuta_inc        char(1),  ---GCR
   @w_garchq             catalogo, --DAR 24/Oct/2013      
   @w_ve_num_factura     varchar(20)

select @w_today          = convert(varchar(10),getdate(),101),
       @w_fecha_hoy      = @s_date,
       @w_sp_name        = 'sp_recuperacion',
       @w_est_credito    = 99, ---GCR
       @w_est_no_vigente = 0,  ---GCR
       @w_est_cancelado  = 3,  ---GCR
       @w_est_anulado    = 11  ---GCR


select @w_garchq = pa_char   --990
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'CHQCOB'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19020 and @i_operacion = 'I') or
   (@t_trn <> 19021 and @i_operacion = 'U') or
   (@t_trn <> 19022 and @i_operacion = 'D') or
   (@t_trn <> 19023 and @i_operacion = 'V') or
   (@t_trn <> 19024 and @i_operacion = 'S') or
   (@t_trn <> 19025 and @i_operacion = 'Q') or
   (@t_trn <> 19026 and @i_operacion = 'A') or
   (@t_trn <> 19027 and @i_operacion = 'Z')
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end



/* Chequeo de Existencias */
/**************************/
if @i_operacion not in ('S','A')
begin

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    select 
         @w_filial = re_filial,
         @w_sucursal = re_sucursal,
         @w_tipo_cust = re_tipo_cust,
         @w_custodia = re_custodia,
         @w_recuperacion = re_recuperacion,
         @w_valor = re_valor,
         @w_ret_iva = isnull(re_ret_iva,0), ---GCR
         @w_ret_fte = isnull(re_ret_fte,0), ---GCR
         @w_vencimiento = re_vencimiento,
         @w_fecha = re_fecha,
         @w_cobro_mora = re_cobro_mora,
         @w_cobro_comision = re_cobro_comision,
         @w_operacion      = re_operacion, ---GCR
         @w_secuencial_ing = re_secuencial_ab ---GCR
    from cob_custodia..cu_recuperacion
    where 
         re_codigo_externo = @w_codigo_externo and
         re_recuperacion = @i_recuperacion

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_filial = NULL or 
       @i_sucursal = NULL or 
       @i_tipo_cust = NULL or 
       @i_custodia = NULL or 
       @i_valor = NULL 
    begin
       /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end

    ---GCR: Valores Definidos del Documento
    select @w_cobro_vencimiento = isnull(ve_valor,0), 
           @w_ve_ret_iva = isnull(ve_ret_iva,0), ---GCR
           @w_ve_ret_fte = isnull(ve_ret_fte,0), ---GCR
           @w_ve_num_factura = ve_num_factura    ---DAR 28OCT2013
    from cu_vencimiento
    where ve_codigo_externo = @w_codigo_externo 
      and ve_vencimiento = @i_vencimiento     

    ---GCR: Total de recuperaciones
    select @w_valor_aux = isnull(sum(re_valor),0),
           @w_tret_iva = isnull(sum(re_ret_iva),0),
           @w_tret_fte = isnull(sum(re_ret_fte),0)  --Oct.25.2007
    from cu_recuperacion
    where re_codigo_externo = @w_codigo_externo 
      and re_vencimiento = @i_vencimiento

    ---GCR
    ---Validar que la garantÂ¡a este adjunta a una operacion
    -------------------------------------------------------
    select @w_banco = null

    if @i_tipo_cust <> @w_garchq
    begin
       select @w_banco = op_banco,
           @w_operacion = op_operacion,
           @w_estado_op = op_estado
        from cob_cartera..ca_operacion,
           cob_credito..cr_gar_propuesta
       where gp_tramite = op_tramite
         and gp_garantia = @w_codigo_externo
    

	    if (@w_banco is null and @i_operacion = 'I')
	    begin 
	      exec cobis..sp_cerror
	       @t_debug = @t_debug,
	       @t_file  = @t_file, 
	       @t_from  = @w_sp_name,
	       @i_num   = 1901027
	      return 1 
	    end 

	    ---La operacion debe estar vigente
	    ----------------------------------
	    if (@w_estado_op in (@w_est_credito, @w_est_no_vigente)) and (@i_operacion = 'I')
	    begin 
	      exec cobis..sp_cerror
	       @t_debug = @t_debug,
	       @t_file  = @t_file, 
	       @t_from  = @w_sp_name,
	       @i_num   = 710025
	      return 1 
	    end    
    end
end


/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
       /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end


    ---GCR:Valor neto de recuperaciones mayor que el del Documento
    if (@w_valor_aux + @i_valor) > (@w_cobro_vencimiento - @w_ve_ret_iva - @w_ve_ret_fte)
    begin           
--print 'A %1! %2! ', @w_valor_aux , @i_valor
--print '  %1! %2! %3!', @w_cobro_vencimiento, @w_ve_ret_iva, @w_ve_ret_fte

           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

    ---GCR:Valor Retencion Iva mayor al definido
    if (@w_tret_iva + @i_ret_iva) > @w_ve_ret_iva
    begin           
--print 'B %1! %2!', @w_tret_iva, @i_ret_iva
--print '  %1!',  @w_ve_ret_iva

           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

    ---GCR:Valor Retencion Fuente mayor al definido
    if (@w_tret_fte + @i_ret_fte) > @w_ve_ret_fte  --LRC oct.25.2007
    begin           
--print 'C %1! %2!', @w_tret_fte, @i_ret_fte
--print '  %1! ', @w_ve_ret_fte  
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    if not exists(select 1 from cu_vencimiento
                   where ve_codigo_externo = @w_codigo_externo 
                     and ve_vencimiento    = @i_vencimiento)
    begin
       /* Registro consultado no existe */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 1901005
       return 1 
    end
    else 
     begin
      select @w_ultimo = isnull(max(re_recuperacion),0) + 1
      from cu_recuperacion
      where re_codigo_externo = @w_codigo_externo


    /* NO RECUPERAR SI LA GARANTIA ESTA PROPUESTA */
    select @w_estado_gar = cu_estado,
           @w_moneda = cu_moneda ----GCR
      from cu_custodia
     where cu_codigo_externo = @w_codigo_externo
    
    if @w_estado_gar = 'P'
    begin
         /* No se puede recuperar una garantia en estado de Propuesta */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1903009
            return 1
    end

    if @w_estado_gar = 'C'
    begin
         /* No se puede recuperar una garantia en estado Cancelada */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901015
            return 1
    end

    create table #rubros_tmp (
      concepto   varchar(10),
      tipo_rubro char(1) )

    create table #orden_prioridades  (
      operacion  int,
      concepto   catalogo, 
      prioridad  int,
      tipo_rubro char(1),
      fpago      char(1))

    begin tran

         /*GCR: SECCION ELIMINADA POR NO APLICAR*/

         select @w_valor_aux = @w_valor_aux + @w_tret_iva + @w_tret_fte
         select @w_diferencia = @w_cobro_vencimiento-@w_valor_aux - (@i_valor + @i_ret_iva + @i_ret_fte) ---GCR
    
    --print '@w_ultimo %1! @i_vencimiento %2! @w_codigo_externo %3!', @w_ultimo, @i_vencimiento, @w_codigo_externo
    
	--print ' @i_filial %1! @i_sucursal %2! @i_tipo_cust %3! @i_custodia %4! @i_valor %5!',
	  --     @i_filial, @i_sucursal, @i_tipo_cust, @i_custodia, @i_valor

         /* Insercion del registro */
         insert into cu_recuperacion(
              re_filial,
              re_sucursal,
              re_tipo_cust,
              re_custodia,
              re_recuperacion,
              re_valor,
              re_ret_iva, ---GCR
              re_ret_fte, ---GCR
              re_vencimiento,
              re_fecha,
              re_cobro_comision,
              re_cobro_mora,
              re_codigo_externo)
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @w_ultimo,
              @i_valor,
              @i_ret_iva, ---GCR
              @i_ret_fte, ---GCR
              @i_vencimiento,
              @i_fecha,
              @i_cobro_comision,
              @i_cobro_mora,
              @w_codigo_externo) 

         if @@error <> 0 
         begin
            /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/
         insert into ts_recuperacion
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_recuperacion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_recuperacion,
         @i_valor,
         @i_ret_iva, ---GCR
         @i_ret_fte, ---GCR
         @i_vencimiento,
         @i_fecha,
         @i_cobro_vencimiento,
         @i_cobro_mora,
         @i_cobro_comision,
         @w_codigo_externo) 

         if @@error <> 0 
         begin
            /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

         ---GCR
         if @w_diferencia = 0 ---Se cancela el documento
         begin         
           update cu_vencimiento
              set ve_estado = 'P',
                  ve_fecha_tolerancia = @s_date  --DAR 14NOV2013
             from cu_vencimiento 
            where ve_codigo_externo  = @w_codigo_externo 
              and ve_vencimiento   = @i_vencimiento

           if @@error <> 0 
           begin
             /* Error en actualizacion de registro */
              exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1905001
              return 1 
           end

           if @i_tipo_cust = @w_garchq --ACTUALIZAR ESTADO DEL CHEQUE PARA COBRANZAS
           begin
              update cob_credito..cr_cheques_cobranza
                 set cc_estado = 'P'
               where cc_custodia      = @i_custodia
                 and cc_nro_vec_doc   = @i_vencimiento
           end           
         end

         
         if @i_valor > 0      
            select @w_debcred = 'D',
                   @w_descripcion = 'COBRO DOCUMENTO #' + @w_ve_num_factura + ' VCTO.#' + convert(varchar(20),@i_vencimiento)
         else
            select @w_debcred = 'C',
                   @w_descripcion = 'REV.COBRO DOCUMENTO #' + @w_ve_num_factura + ' VCTO.#' + convert(varchar(20),@i_vencimiento)

         /********COMENTADO PORQUE EL USUARIO NO DESEA AUTOMATICO PAGO A CARTERA
         ---GCR:
         ---INTERFAZ CON CARTERA  
         -----------------------
         if (@i_fecha = @s_date) and  (@w_debcred = 'D' ) and
            (@w_estado_op not in (@w_est_cancelado,@w_est_anulado))
         begin


           exec @w_status = cob_cartera..sp_pago_cartera
           @s_user     = @s_user,
           @s_term     = @s_term,
           @s_date     = @s_date ,
           @s_sesn     = @s_sesn,
           @s_ssn      = @s_ssn,
           @s_ofi      = @s_ofi ,
           @s_srv      = @s_srv,
           @s_lsrv     = @s_lsrv,
           @t_debug    = 'N',
           @t_file     = @t_file,
           @t_from     = @t_from,
           @i_banco    = @w_banco,
           @i_beneficiario = @w_descripcion, 
           @i_fecha_vig = @i_fecha,
           @i_ejecutar  = 'S',
           @i_en_linea  = 'S',
           @i_producto  = @i_producto,
           @i_monto_mpg = @i_valor,
           @i_cuenta    = @i_cuenta,
           @i_moneda    = @i_moneda,
           @i_monto_mop = @i_monto_mop, 
           @i_monto_mn   = @i_monto_mn, 
           @i_cotizacion_mpg  = @i_cotizacion_mpg, 
           @i_tcotizacion_mpg = @i_tcotizacion_mpg,
           @i_cotizacion_mop  = @i_cotizacion_mop, 
           @i_tcotizacion_mop = @i_tcotizacion_mop,
           @o_secuencial_ing = @w_secuencial_ing out

           if @w_status <> 0 
           begin
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = @w_status --LRC oct.25.2007  --708154
               return 1 
           end

         end ----Interfaz con Cartera 

         ---GCR: Verificar si el Pago cancelo el Credito.
         if exists (select 1
                      from cob_cartera..ca_operacion
                         where op_banco = @w_banco
                           and op_estado in (@w_est_cancelado,@w_est_anulado))
            select @w_cancelado = 'S'
         else 
          ********COMENTADO PORQUE EL USUARIO NO DESEA AUTOMATICO  ***/
            select @w_cancelado = 'N'          

           ---Grabar sec.abono
           update cu_recuperacion
              set re_operacion = @w_operacion
                  --re_secuencial_ab = @w_secuencial_ing
            where re_codigo_externo = @w_codigo_externo 
              and re_vencimiento    = @i_vencimiento
              and re_recuperacion   = @w_ultimo


         /* Generacion de la transaccion monetaria */
         select @w_valor_absoluto = isnull(abs (@i_valor),0)
         select @w_valor_trn = @w_valor_absoluto + isnull(@i_ret_iva,0) + isnull(@i_ret_fte,0) ---GCR

         if @w_cancelado = 'N' ---GCR: Recuperacion que no cancela la Garantia
         begin 
            
            exec @w_status = sp_transaccion
                 @s_ssn = @s_ssn,
                 @s_ofi = @s_ofi,
                 @s_date = @s_date,
                 @t_trn = 19000,
                 @i_operacion = 'I',
                 @i_filial = @i_filial,
                 @i_sucursal = @i_sucursal,
                 @i_tipo_cust = @i_tipo_cust,
                 @i_custodia = @i_custodia,
                 @i_fecha_tran = @s_date,
                 @i_debcred =  @w_debcred, 
                 @i_valor = @w_valor_trn, ---GCR
                 @i_descripcion = @w_descripcion,
                 @i_usuario = @s_user  

            if @w_status <> 0 
            begin
               /* Error en insercion de Registro Contable */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901012
                return 1 
            end
         end        
         
         select @w_ultimo
       end
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/
/* OPCION NO USADA */
if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
       /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    select @w_valor_aux = @w_valor_aux - @w_valor,
           @w_tret_iva = @w_tret_iva - @w_ret_iva,
           @w_tret_fte =  @w_tret_fte - @w_ret_fte


    ---GCR:Valor neto de recuperaciones mayor que el del Documento
    if (@w_valor_aux + @i_valor) > (@w_cobro_vencimiento - @w_ve_ret_iva - @w_ve_ret_fte)
    begin           
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

    ---GCR:Valor Retencion Iva mayor al definido
    if (@w_tret_iva + @i_ret_iva) > @w_ve_ret_iva
    begin           
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

    ---GCR:Valor Retencion Fuente mayor al definido
    if (@w_tret_fte + @i_ret_fte) > @w_ve_ret_fte  --LRC oct.25.2007
    begin           
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905003   
           return 1
    end

    begin tran
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         update cob_custodia..cu_recuperacion
         set 
              re_valor = @i_valor,
              re_ret_iva = @i_ret_iva, ---GCR
              re_ret_fte = @i_ret_fte, ---GCR
              re_vencimiento = @i_vencimiento,
              re_fecha = @i_fecha
         where re_codigo_externo = @w_codigo_externo and
               re_recuperacion = @i_recuperacion

         if @@error <> 0 
         begin
            /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/
         insert into ts_recuperacion
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_recuperacion',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_recuperacion,
         @w_valor,
         @w_ret_iva, ----GCR
         @w_ret_fte, ----GCR
         @w_vencimiento,
         @w_fecha,
         null,
         null,
         null,
         @w_codigo_externo) 

         if @@error <> 0 
         begin
            /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/
         insert into ts_recuperacion
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_recuperacion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_recuperacion,
         @i_valor,         
         @i_ret_iva, ---GCR
         @i_ret_fte, ---GCR
         @i_vencimiento,
         @i_fecha,
         null,
         null,
         null,
         @w_codigo_externo) 

         if @@error <> 0 
         begin
            /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
       /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

    ---Obtener Codigo Externo
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    ---Verificar si existe operacion adjunta    
    select @w_banco = null,
           @w_ejecuta_inc = 'S'  --ejecuta contable

   /******COMENTADO NO APLICA

    select @w_banco = op_banco,
           @w_operacion = op_operacion,
           @w_estado_op = op_estado
      from cob_cartera..ca_operacion
     where op_operacion = @w_operacion

    if @w_banco <> null
    begin
      ---GCR: Obtener secuencial de Pago  
      select @w_secuencial_pag = ab_secuencial_pag
        from cob_cartera..ca_abono
       where ab_operacion = @w_operacion
         and ab_secuencial_ing = @w_secuencial_ing

      ---Variable que indica si se genera trn. de incremento
      if (@w_estado_op <> @w_est_cancelado) 
       select @w_ejecuta_inc = 'S'
    end
    else
       select @w_ejecuta_inc = 'S'


    ---GCR: INTERFAZ CON CARTERA
    ----------------------------

    if (@w_secuencial_pag <> null) and (@w_fecha = @s_date)
    begin
      
      exec @w_status = cob_cartera..sp_fecha_valor
        @s_date        = @s_date,
        @s_lsrv        = @s_lsrv,
        @s_ofi         = @s_ofi,
        @s_org         = @s_org,
        @s_rol         = @s_rol,
        @s_sesn        = @s_sesn,
        @s_ssn         = @s_ssn,
        @s_srv         = @s_srv,
        @s_term        = @s_term,
        @s_user        = @s_user,
        @t_rty         = @t_rty,
        @t_file        = @t_file,
        @t_trn         = 7049,     
        @i_banco       = @w_banco,
        @i_secuencial  = @w_secuencial_pag,
        @i_operacion   = 'R',
        @i_ejecuta_inc = @w_ejecuta_inc,
        @i_codigo_externo = @w_codigo_externo,
        @i_recuperacion = @i_recuperacion

      if @w_status <> 0 
      begin
      print 'b'
       exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = @w_status  --Oct.25.2007 --708154
       return 1 
      end

    end --- (@w_secuencial_pag <> null) 
    
    **********/

      exec @w_status = sp_reverso_recuperacion
        @s_date        = @s_date,
        @s_lsrv        = @s_lsrv,
        @s_ofi         = @s_ofi,
        @s_org         = @s_org,
        @s_rol         = @s_rol,
        @s_sesn        = @s_sesn,
        @s_ssn         = @s_ssn,
        @s_srv         = @s_srv,
        @s_term        = @s_term,
        @s_user        = @s_user,
        @t_rty         = @t_rty,
        @t_file        = @t_file,
        @t_trn         = @t_trn,
        @i_codigo_externo = @w_codigo_externo,
        @i_commit      = 'S',
        @i_recuperacion = @i_recuperacion,   
        @i_ejecuta_inc = @w_ejecuta_inc

      if @w_status <> 0 
      begin
        /* Error en insercion de Registro Contable */
        exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1901012
        return 1 
      end

    return 0

end


/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin
         select @w_des_tipo = tc_descripcion
         from cu_tipo_custodia
         where tc_tipo = @i_tipo_cust

         select @w_fecha_emision = ve_fecha_emision, ---GCR
                @w_fecha_vencimiento = ve_fecha,
                @w_fecha_tolerancia = ve_fecha_tolerancia, ---GCR
                @w_valor_vencimiento = ve_valor,
                @w_beneficiario      = ve_beneficiario,
                @w_deudor            = ve_deudor, ---GCR
                @w_documento         = ve_num_factura ---GCR
         from cu_vencimiento 
         where ve_filial      = @w_filial 
           and ve_sucursal    = @w_sucursal
           and ve_tipo_cust   = @w_tipo_cust 
           and ve_custodia    = @w_custodia
           and ve_vencimiento = @w_vencimiento
        
         select 
              @w_filial,
              @w_sucursal,
              @w_tipo_cust,
              @w_des_tipo,
              @w_custodia,
              @w_recuperacion,
              convert(char(10),@w_fecha,@i_formato_fecha),
              @w_valor,
              @w_vencimiento,
              convert(char(10),@w_fecha_vencimiento,@i_formato_fecha),
              @w_cobro_mora,
              @w_cobro_comision,
              @w_valor_vencimiento,
              @w_beneficiario, ---14
              convert(char(10),@w_fecha_emision,@i_formato_fecha), ---GCR
              convert(char(10),@w_fecha_tolerancia,@i_formato_fecha), ---GCR
              @w_deudor, ---GCR
              @w_documento, ---GCR
              @w_ret_iva, ---GCR
              @w_ret_fte ---GCR
    end
    else
    begin
       /* Registro consultado no existe */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901005
         return 0
    end
end

if @i_operacion = 'S'
begin 

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

   set rowcount 20
   select 'RECUPERACION' = re_recuperacion,
          'DOCUMENTO' = ve_num_factura, ---GCR
          'FECHA'=convert(char(10),re_fecha,@i_formato_fecha),
          'VALOR'=re_valor,
          'RET.IVA'=re_ret_iva, ---GCR
          'RET.FUENTE'=re_ret_fte, ---GCR
          'SALDO' = ve_valor - isnull((select sum(re_valor + isnull(re_ret_iva,0) + isnull(re_ret_fte,0))
                                         from cu_recuperacion
                                        where re_codigo_externo = @w_codigo_externo
                                          and re_vencimiento = R.re_vencimiento
                                          and re_recuperacion <= R.re_recuperacion),0),
          'VENCIMIENTO'=re_vencimiento
   from cu_recuperacion R, cu_vencimiento V
   where re_codigo_externo = @w_codigo_externo
     and ve_filial    = re_filial
     and ve_sucursal  = re_sucursal
     and ve_tipo_cust = re_tipo_cust
     and ve_custodia =  re_custodia
     and ve_vencimiento = re_vencimiento
     and (re_recuperacion > @i_recuperacion or @i_recuperacion is null)
   order by re_recuperacion ----GCR
   set rowcount 0

   /*GCR: Comentado para evitar mensaje de error
   if @@rowcount = 0
   begin
       
       if @i_recuperacion is null  
          select @w_error  = 1901003
       else
          return 1
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
       return 1
   end*/
   
end


if @i_operacion = 'Z'
begin

    select @w_cobro_vencimiento = ve_valor,
           @w_codigo_externo = ve_codigo_externo
    from cu_vencimiento
    where ve_filial      = @i_filial 
      and ve_sucursal    = @i_sucursal
      and ve_tipo_cust   = @i_tipo_cust
      and ve_custodia    = @i_custodia
      and ve_vencimiento = @i_vencimiento

    select @w_valor_aux = @w_cobro_vencimiento - sum(re_valor + isnull(re_ret_iva,0) + isnull(re_ret_fte,0)) - 
                          (@i_valor+ @i_ret_iva + @i_ret_fte) ---GCR
    from cu_recuperacion
    where re_codigo_externo = @w_codigo_externo
      and re_vencimiento = @i_vencimiento
   
    if @w_valor_aux < 0  -- La recuperacion excede el valor del vencimiento
    begin       
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905003 
        return 1 
    end
    else
        return 0 
 end
go