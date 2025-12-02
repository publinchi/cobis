/*************************************************************************/
/*   Archivo:              inspeccion.sp                                 */
/*   Stored procedure:     sp_inspeccion                                 */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_inspeccion') IS NOT NULL
    DROP PROCEDURE dbo.sp_inspeccion
go
create proc sp_inspeccion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
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
   @i_fecha_insp         datetime  = null,
   @i_inspector          tinyint  = null,
   @i_estado             catalogo  = null,
   @i_factura            varchar( 20)  = null,
   @i_valor_fact         money  = 0,
   @i_observaciones      varchar(255)  = null,
   @i_instruccion        varchar(255)  = null,
   @i_motivo             catalogo  = null,
   @i_valor_avaluo       money  = null,
   @i_estado_tramite     char(1) = null,
   @i_periodicidad       catalogo = null,
   @i_tipo_cust1         descripcion = null,
   @i_custodia1          int = null,
   @i_custodia2          int = null,
   @i_custodia3          int = null,
   @i_fecha_insp1        datetime = null,
   @i_fecha_insp2        datetime = null,
   @i_fecha_insp3        datetime = null,
   @i_oficial1           smallint = null,
   @i_oficial2           smallint = null,
   @i_formato_fecha	 int = null,
   @i_todas              char(1) = null,
   @i_cliente            int = null,
   @i_fecha_reporte      datetime = null,
   @i_fecha_carta        datetime = null
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
   @w_fecha_insp         datetime,
   @w_inspector          tinyint,
   @w_estado             catalogo,
   @w_factura            varchar( 20),
   @w_valor_fact         money,
   @w_observaciones      varchar(255),
   @w_instruccion        varchar(255),
   @w_motivo             catalogo,
   @w_valor_avaluo       money,
   @w_estado_tramite	 char(1),
   @w_error 		 int,
   @w_periodicidad       catalogo,
   @w_des_periodicidad   descripcion,
   @w_des_est_inspeccion descripcion,
   @w_des_cliente        varchar(255),
   @w_des_inspector      descripcion,
   @w_des_tipo 		 descripcion,
   @w_valor_actual       money,
   @w_valor_total        money,
   @w_debcred            char(1),
   @w_descripcion        descripcion,
   @w_valor_tran         money,
   @w_num_inspeccion     tinyint,
   @w_ultima_fecha       datetime,
   @w_fecha_carta        datetime,
   @w_fecha_asig         datetime, 
   @w_status		 int,
   @w_nombre_cliente     varchar(64),
   @w_codigo_externo     varchar(64),
   @w_nro_clientes       tinyint,
   @w_valor_intervalo    tinyint,
   @w_estado_garantia    char(1),
   @w_valor_anterior     money,
   @w_valor              money,
   @w_fenvio_carta       datetime,
   @w_frecep_reporte     datetime,
   @w_ultimo             tinyint


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_inspeccion'


/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19060 and @i_operacion = 'I') or
   (@t_trn <> 19061 and @i_operacion = 'U') or
   (@t_trn <> 19062 and @i_operacion = 'D') or
   (@t_trn <> 19063 and @i_operacion = 'V') or
   (@t_trn <> 19064 and @i_operacion = 'S') or
   (@t_trn <> 19065 and @i_operacion = 'Q') or
   (@t_trn <> 19066 and @i_operacion = 'A') or 
   (@t_trn <> 19067 and @i_operacion = 'C') or /* Prendas por cobrar */
   (@t_trn <> 19068 and @i_operacion = 'Z') or
   (@t_trn <> 19069 and @i_operacion = 'M') or
   (@t_trn <> 19077 and @i_operacion = 'B') or
   (@t_trn <> 19078 and @i_operacion = 'N') or
   (@t_trn <> 19734 and @i_operacion = 'E') 
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

if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_filial = in_filial,
         @w_sucursal = in_sucursal,
         @w_tipo_cust = in_tipo_cust,
         @w_custodia = in_custodia,
         @w_fecha_insp = in_fecha_insp,
         @w_inspector = in_inspector,
         @w_estado = in_estado,
         @w_factura = in_factura,
         @w_valor_fact = in_valor_fact,
         @w_observaciones = in_observaciones,
         @w_instruccion = in_instruccion,
         @w_motivo = in_motivo,
         @w_valor_avaluo = in_valor_avaluo,
         @w_estado_tramite = in_estado_tramite,
         @w_codigo_externo = in_codigo_externo
    from cob_custodia..cu_inspeccion
    where 
         in_filial     = @i_filial and
         in_sucursal   = @i_sucursal and
         in_tipo_cust  = @i_tipo_cust and
         in_custodia   = @i_custodia 
	-- VDA 07/15/2005
	 /*and
         in_fecha_insp = @i_fecha_insp*/

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/

if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         @i_filial = NULL or 
         @i_sucursal = NULL or 
         @i_tipo_cust = NULL or 
         @i_custodia = NULL 
	 -- VDA 07/15/2005
	 /*or 
         @i_fecha_insp = NULL */
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end

    if @i_valor_fact = 0 or @i_valor_fact is null
       select @i_estado_tramite = 'S'
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
    /* Ya existe el registro */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1903002
        return 1 
    end
    else

    begin

    begin tran

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         insert into cu_inspeccion(
              in_filial,
              in_sucursal,
              in_tipo_cust,
              in_custodia,
              in_fecha_insp,
              in_inspector,
              in_estado,
              in_factura,
              in_valor_fact,
              in_observaciones,
              in_instruccion,
              in_motivo,
              in_valor_avaluo,
              in_estado_tramite,
              in_codigo_externo)

         values (
              @i_filial,
              @i_sucursal,
              @i_tipo_cust,
              @i_custodia,
              @i_fecha_insp,
              @i_inspector,
              @i_estado,
              @i_factura,
              @i_valor_fact,
              @i_observaciones,
              @i_instruccion,
              @i_motivo,
              @i_valor_avaluo,
              @i_estado_tramite,
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

         -- MODIFICA LA FECHA Y VALOR DEL CONTROL DE INSPECTORES
	 --VDA 07/14/2005
         /*if exists (select * from cu_control_inspector
                     where ci_inspector = @i_inspector
                       and ci_fenvio_carta = @i_fecha_carta)
         begin  
            select @w_valor_anterior = isnull(ci_valor_facturado,0)
              from cu_control_inspector
             where ci_inspector    = @i_inspector
               and ci_fenvio_carta = @i_fecha_carta

            select @w_valor_anterior = isnull(@w_valor_anterior,0) 

             update cu_control_inspector
             set ci_frecep_reporte  = @i_fecha_reporte,
                 ci_valor_facturado = isnull(@w_valor_anterior,0)+
                                     isnull(@i_valor_fact,0)
             where  ci_inspector    = @i_inspector
               and  ci_fenvio_carta = @i_fecha_carta
         end

         else
         begin
             /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903005
             return 1 
         end*/

        -- OBTENGO EL ESTADO DE LA GARANTIA
        select @w_estado_garantia = cu_estado
        from cu_custodia
        where cu_codigo_externo = @w_codigo_externo

        -- MODIFICAR EL VALOR DE LA GARANTIA
        if @i_valor_avaluo <> null
        begin
             select @w_valor_actual = cu_valor_actual 
             from cu_custodia
             where cu_filial   = @i_filial
               and cu_sucursal = @i_sucursal
               and cu_tipo     = @i_tipo_cust
               and cu_custodia = @i_custodia

             if @w_valor_actual < @i_valor_avaluo 
               select @w_debcred = 'C'
            else
               select @w_debcred = 'D'

            select @w_descripcion = 'RESULTADO DE AVALUO DE INSPECCION FECHA ' + convert(char(10),@i_fecha_insp,101)

            select @w_valor_tran = abs (@i_valor_avaluo - @w_valor_actual) 

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
              @i_valor = @w_valor_tran,
              @i_descripcion = @w_descripcion,
              @i_usuario = @s_user,
              @i_estado_aux = @w_estado_garantia   

            if @w_status <> 0
               return 1 
        end

        -- SE INCREMENTA EL NUMERO DE INSPECCIONES

        update cob_custodia..cu_custodia
        set    cu_nro_inspecciones = isnull(cu_nro_inspecciones,0) + 1
        where  cu_filial = @i_filial and
               cu_sucursal = @i_sucursal and
               cu_tipo = @i_tipo_cust and
               cu_custodia = @i_custodia

        -- SI CAMBIA LA PERIODICIDAD
        if @i_periodicidad <> '' or @i_periodicidad is not null
        begin
               if @i_periodicidad = '1' /* Mensual */
                  select @w_valor_intervalo = 1

               if @i_periodicidad = '2' /* Mensual */
                  select @w_valor_intervalo = 2

               if @i_periodicidad = '3' /* Trimestral */
                  select @w_valor_intervalo = 3

               if @i_periodicidad = '6' /* Semestral */
                  select @w_valor_intervalo = 6

               if @i_periodicidad = '12' /* Anual */
                  select @w_valor_intervalo = 12
        end

        update cob_custodia..cu_custodia
        set cu_periodicidad  = @i_periodicidad, -- Nueva periodicidad
            cu_fecha_insp    = @i_fecha_insp,   -- Ultima fecha de inspeccion
            cu_intervalo     = @w_valor_intervalo,
            cu_fecha_prox_insp = dateadd(mm,@w_valor_intervalo,@i_fecha_insp)
        where cu_filial = @i_filial and
              cu_sucursal = @i_sucursal and
              cu_tipo = @i_tipo_cust and
              cu_custodia = @i_custodia

       -- SE BORRA DE LA TABLA CU_POR_INSPECCIONAR
       update cob_custodia..cu_por_inspeccionar 
       set    pi_inspeccionado = 'S',
              pi_fecha_insp = @i_fecha_insp,
              pi_inspector_ant = @i_inspector,
              pi_estado_ant    = @i_estado
       where  pi_filial   = @i_filial and
              pi_sucursal = @i_sucursal and 
              pi_tipo     = @i_tipo_cust and
              pi_custodia = @i_custodia and
              pi_inspeccionado = 'N'

       -- SE CALCULAN VALORES PARA LA TABLA CU_CONTROL_INSPECTOR
       select @w_valor_total = sum(isnull(in_valor_fact,0)) +
                               isnull(@i_valor_fact,0) 
       from cu_inspeccion
       where in_inspector   = @i_inspector

       if @@error <> 0 
       begin
           /* Error en insercion del registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
       end

       /* Transaccion de Servicio */
       /***************************/
       insert into ts_inspeccion
       values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_inspeccion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_fecha_insp,
         @i_inspector,
         @i_estado,
         @i_factura,
         @i_valor_fact,
         @i_observaciones,
         @i_instruccion,
         @i_motivo,
         @i_valor_avaluo,
         @i_estado_tramite,
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

    /** SI SE INGRESA UNA INSPECCION SE REGULARIZA LAS EXCEPCION CON AVALUOS VENCIDOS **/
    /** VERIFICANDO QUE LA NUEVA FECHA DE INSPECCION SEA MAYOR AL DIA DE HOY.     **/
    --VIVI, 14/Abr/08
    if @i_fecha_insp > @w_today 
    begin
	    if exists( select 1 from cob_credito..cr_excepciones
		       where ex_codigo       = '3G'	
			 and ex_fecha_regula is null 
			 and ex_garantia     = @w_codigo_externo)
	    begin

	      update cob_credito..cr_excepciones
	         set ex_fecha_regula  = @s_date,
	             ex_razon_regula  = @i_motivo,
	             ex_estado        = 'R',
	             ex_login_regula  = @s_user
	       where ex_codigo       = '3G'
		 and ex_fecha_regula is null 
		 and ex_garantia     = @w_codigo_externo

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
	   end		--If exists		
    end
    /** FIN de @i_fecha_insp > @w_today **/

    commit tran

    return 0

    end 
end



/* Actualizacion del registro */
/******************************/
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
    else
    begin
         begin tran
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         /*if @w_estado_tramite = 'S'    --  VDA 07/27/2005
         begin
             /* No se puede modificar una inspeccion cobrada */
              exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905011
              return 1 
         end*/
            
         update cob_custodia..cu_inspeccion
         set  in_inspector = @i_inspector,
              in_estado = @i_estado,
              in_factura = @i_factura,
              in_valor_fact = @i_valor_fact,
              in_observaciones = @i_observaciones,
              in_instruccion = @i_instruccion,
              in_motivo = @i_motivo,
              in_valor_avaluo = @i_valor_avaluo,
              in_codigo_externo = @w_codigo_externo,
	      in_fecha_insp = @i_fecha_insp
         where in_filial = @i_filial and
               in_sucursal = @i_sucursal and
               in_tipo_cust = @i_tipo_cust and
               in_custodia = @i_custodia 
	       -- VDA 07/15/2005
	       /*and
               in_fecha_insp = @i_fecha_insp*/

         -- SE ACTUALIZA LA TABLA CU_POR_INSPECCIONAR
         update cob_custodia..cu_por_inspeccionar 
         set  pi_fecha_insp = @i_fecha_insp
         where pi_filial   = @i_filial and
               pi_sucursal = @i_sucursal and 
               pi_tipo     = @i_tipo_cust and
               pi_custodia = @i_custodia and
               pi_inspeccionado = 'S'

         -- MODIFICA LA FECHA Y VALOR DEL CONTROL DE INSPECTORES
         select @w_valor_anterior = isnull(ci_valor_facturado,0)
         from cu_control_inspector
         where ci_inspector    = @i_inspector
           and ci_fenvio_carta = @i_fecha_carta

         if @i_valor_fact <> @w_valor_fact
            select @w_valor_anterior = isnull(@w_valor_anterior,0) - 
                                       isnull(@w_valor_fact,0) +
                                       isnull(@i_valor_fact,0)

         select @w_valor_anterior = isnull(@w_valor_anterior,0)

         update cu_control_inspector
         set ci_frecep_reporte  = @i_fecha_reporte,
             ci_valor_facturado = isnull(@w_valor_anterior,0)
         where  ci_inspector    = @i_inspector
           and  ci_fenvio_carta = @i_fecha_carta

        -- OBTENGO EL ESTADO DE LA GARANTIA MVI 07/01/96
        select @w_estado_garantia = cu_estado
        from cu_custodia
        where cu_codigo_externo = @w_codigo_externo

        if @i_valor_avaluo <> null  -- MODIFICAR EL VALOR DE LA GARANTIA
        begin
           select @w_valor_actual = cu_valor_actual 
           from cu_custodia
           where cu_filial   = @i_filial
             and cu_sucursal = @i_sucursal
             and cu_tipo     = @i_tipo_cust
             and cu_custodia = @i_custodia

           if @w_valor_actual < @i_valor_avaluo 
               select @w_debcred = 'C'
           else
               select @w_debcred = 'D'

           select @w_descripcion = 'RESULTADO DE AVALUO DE INSPECCION FECHA ' + convert(char(10),@i_fecha_insp,101)
           select @w_valor_tran = abs (@i_valor_avaluo - @w_valor_actual) 

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
              @i_valor = @w_valor_tran,
              @i_descripcion = @w_descripcion,
              @i_usuario = @s_user,
              @i_estado_aux = @w_estado_garantia 

           if @w_status <> 0
               return 1
        end

        if @i_periodicidad <> '' or @i_periodicidad is not null
        begin
             if @i_periodicidad = '1' /* Mensual */
                select @w_valor_intervalo = 1

             if @i_periodicidad = '2' /* Mensual */
                select @w_valor_intervalo = 2

             if @i_periodicidad = '3' /* Trimestral */
                select @w_valor_intervalo = 3

             if @i_periodicidad = '6' /* Semestral */
                select @w_valor_intervalo = 6

             if @i_periodicidad = '12' /* Anual */
                select @w_valor_intervalo = 12
        end

        update cob_custodia..cu_custodia
        set  cu_periodicidad = @i_periodicidad,
             cu_fecha_insp   = @i_fecha_insp,
             cu_intervalo    = @w_valor_intervalo,
             cu_fecha_prox_insp = dateadd(mm,@w_valor_intervalo,@i_fecha_insp)
        where cu_filial = @i_filial and
              cu_sucursal = @i_sucursal and
              cu_tipo = @i_tipo_cust and
              cu_custodia = @i_custodia and
              cu_periodicidad <> @i_periodicidad

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
         insert into ts_inspeccion
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_inspeccion',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_fecha_insp,
         @w_inspector,
         @w_estado,
         @w_factura,
         @w_valor_fact,
         @w_observaciones,
         @w_instruccion,
         @w_motivo,
         @w_valor_avaluo,
         @w_estado_tramite,
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
         insert into ts_inspeccion
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_inspeccion',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_fecha_insp,
         @i_inspector,
         @i_estado,
         @i_factura,
         @i_valor_fact,
         @i_observaciones,
         @i_instruccion,
         @i_motivo,
         @i_valor_avaluo,
         @i_estado_tramite,
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

       /** SI SE INGRESA UNA INSPECCION SE REGULARIZA LAS EXCEPCION CON AVALUOS VENCIDOS **/
       /** VERIFICANDO QUE LA NUEVA FECHA DE INSPECCION SEA MAYOR AL DIA DE HOY.     **/
       --VIVI, 14/Abr/08

       if @i_fecha_insp > @w_today 
       begin
	    if exists( select 1 from cob_credito..cr_excepciones
		       where ex_codigo       = '3G'	
			 and ex_fecha_regula is null 
			 and ex_garantia     = @w_codigo_externo)
	    begin

	      update cob_credito..cr_excepciones
	         set ex_fecha_regula  = @s_date,
	             ex_razon_regula  = @i_motivo,
	             ex_estado        = 'R',
	             ex_login_regula  = @s_user
	       where ex_codigo       = '3G'	
		 and ex_fecha_regula is null 
		 and ex_garantia     = @w_codigo_externo

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

	   end		--If exists		
       end
       /** FIN de @i_fecha_insp > @w_today **/

    commit tran

    return 0

    end
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

    if @w_estado_tramite = 'S'
    begin
       /* No se puede modificar una inspeccion cobrada */
       exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 1905011
       return 1 
    end         

    /***** Integridad Referencial *****/
    /*****                        *****/
    begin tran
         delete cob_custodia..cu_inspeccion
         where in_filial = @i_filial and
               in_sucursal = @i_sucursal and
               in_tipo_cust = @i_tipo_cust and
               in_custodia = @i_custodia and
               in_fecha_insp = @i_fecha_insp

         if @@error <> 0
         begin
             /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

         -- ELIMINA EL VALOR DEL CONTROL DE INSPECTORES
         select @w_valor_anterior = isnull(ci_valor_facturado,0)
         from cu_control_inspector
         where ci_inspector    = @i_inspector
           and ci_fenvio_carta = @i_fecha_carta

         select @w_valor_anterior = isnull(@w_valor_anterior,0) - 
                                    isnull(@w_valor_fact,0) 
        
         update cu_control_inspector
         set ci_valor_facturado = isnull(@w_valor_anterior,0)
         where  ci_inspector    = @i_inspector
           and  ci_fenvio_carta = @i_fecha_carta
            
         -- ACTUALIZO LA TABLA DE POR INSPECCIONAR
         -- **************************************
         update cu_por_inspeccionar
         set pi_inspeccionado = 'N'
         where pi_filial   = @i_filial and
               pi_sucursal = @i_sucursal and 
               pi_tipo     = @i_tipo_cust and
               pi_custodia = @i_custodia and
               pi_inspeccionado = 'S' and
               pi_fecha_insp    = @i_fecha_insp

          -- MODIFICA EL VALOR DE LA GARANTIA  MVI 08/14/96
          --***********************************************
          select @w_estado_garantia = cu_estado
          from cu_custodia
          where cu_codigo_externo = @w_codigo_externo

          if @w_valor_avaluo <> null  -- MODIFICAR EL VALOR DE LA GARANTIA
          begin
             select @w_valor_actual = cu_valor_actual 
             from cu_custodia
             where cu_filial   = @i_filial
               and cu_sucursal = @i_sucursal
               and cu_tipo     = @i_tipo_cust
               and cu_custodia = @i_custodia

             select @w_debcred = tr_debcred,
                    @w_valor   = tr_valor
             from cu_transaccion
             where tr_codigo_externo = @w_codigo_externo
               and tr_descripcion like 'RESULTADO DE AVALUO DE INSPECCION%'

             if @w_debcred = 'D' 
                select @w_debcred = 'C'
             else
                select @w_debcred = 'D'

             select @w_descripcion = 'REVERSA DE AVALUO DE INSPECCION FECHA ' + convert(char(10),@i_fecha_insp,101)
             select @w_valor_tran = abs(@w_valor) 

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
              @i_valor = @w_valor_tran,
              @i_descripcion = @w_descripcion,
              @i_usuario = @s_user,
              @i_estado_aux = @w_estado_garantia

	     if @w_status <> 0
               return 1
          end
          
         /* Transaccion de Servicio */
         /***************************/
         insert into ts_inspeccion
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_inspeccion',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_fecha_insp,
         @w_inspector,
         @w_estado,
         @w_factura,
         @w_valor_fact,
         @w_observaciones,
         @w_instruccion,
         @w_motivo,
         @w_valor_avaluo,
         @w_estado_tramite,
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



/* Consulta opcion QUERY */

/*************************/

if @i_operacion = 'Q'
begin   

    if @w_existe = 1

    begin

        select @w_des_tipo = tc_descripcion
        from cu_tipo_custodia 
        where tc_tipo = @w_tipo_cust

        select @w_des_est_inspeccion = A.valor
        from cobis..cl_catalogo A,cobis..cl_tabla B
        where B.codigo = A.tabla and
              B.tabla  = 'cu_est_inspeccion' and
              A.codigo = @w_estado

        select @w_fenvio_carta   = ci_fenvio_carta,
               @w_frecep_reporte = ci_frecep_reporte
        from cu_control_inspector
        where ci_inspector = @w_inspector

        select @w_periodicidad = cu_periodicidad
        from cu_custodia
        where cu_codigo_externo = @w_codigo_externo

        select @w_des_periodicidad = A.valor
        from cobis..cl_catalogo A,cobis..cl_tabla B
        where B.codigo = A.tabla and
              B.tabla  = 'cu_des_periodicidad' and
              A.codigo = @w_periodicidad

        set rowcount 1
    
        select @w_des_cliente = convert(varchar(10),cg_ente) + '  ' + cg_nombre
        from cu_cliente_garantia 
        where cg_codigo_externo = @w_codigo_externo 
          and cg_principal = 'S'

        set rowcount 0      

        select @w_des_inspector = is_nombre
        from cu_inspector
        where is_inspector  = @w_inspector

        select 
              @w_filial,
              @w_sucursal,
              @w_tipo_cust,
              @w_des_tipo,
              @w_custodia,
              @w_des_cliente,
              isnull(convert(varchar(20),@w_inspector),''),
              @w_des_inspector,
              @w_estado,
              @w_des_est_inspeccion,
              @w_factura,
              @w_valor_fact,
              convert(char(10),@w_fecha_insp,101),
              @w_valor_avaluo,
              @w_periodicidad,
              @w_des_periodicidad,
              @w_observaciones,
              @w_instruccion,
              convert(char(10),@w_fenvio_carta,@i_formato_fecha),
              convert(char(10),@w_frecep_reporte,@i_formato_fecha)

            /*  @w_motivo,
              @w_estado_tramite */
    end
    else
    begin
         select @w_inspector = pi_inspector_asig
         from cu_por_inspeccionar
         where pi_filial    = @i_filial 
           and pi_sucursal  = @i_sucursal
           and pi_tipo      = @i_tipo_cust
           and pi_custodia  = @i_custodia          

         select @w_des_inspector = is_nombre  
         from cu_inspector
         where is_inspector  = @w_inspector  

         select @w_periodicidad = cu_periodicidad
         from cu_custodia
         where cu_filial   = @i_filial
           and cu_sucursal = @i_sucursal
           and cu_tipo     = @i_tipo_cust
           and cu_custodia = @i_custodia             

         select @w_des_periodicidad = A.valor         
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla 
           and B.tabla  = 'cu_des_periodicidad' 
           and A.codigo = @w_periodicidad

	-- VDA 07/20/2005
	select @w_codigo_externo = cu_codigo_externo
	from cu_custodia
	where cu_filial = @i_filial and
        cu_sucursal = @i_sucursal and
        cu_tipo = @i_tipo_cust and
        cu_custodia = @i_custodia  

	-- VDA 07/20/2005
	select @w_des_cliente = convert(varchar(10),cg_ente) + '  ' + cg_nombre   -- VDA 07/20/2005
        from cu_cliente_garantia 
        where cg_codigo_externo = @w_codigo_externo 
          and cg_principal = 'S'

         select @w_inspector,
                @w_des_inspector,
                @w_periodicidad,
                @w_des_periodicidad,
		@w_des_cliente -- VDA 07/20/2005
        return 1 
    end
    return 0
end


if @i_operacion = 'S'
begin

      set rowcount 20
      select distinct 'GARANTIA' = in_custodia, 
			 'TIPO' = in_tipo_cust,
             'DESC' = tc_descripcion,
             'FECHA' = convert(varchar(10),in_fecha_insp,@i_formato_fecha),
             'ESTADO' = in_estado, 
             'INSPECTOR' = in_inspector
      from cu_inspeccion,cu_custodia,cu_tipo_custodia
      where in_filial = @i_filial
        and in_sucursal = @i_sucursal
        and in_codigo_externo = cu_codigo_externo
        and tc_tipo = cu_tipo
        and (in_tipo_cust like @i_tipo_cust or @i_tipo_cust is null) 
        and (in_custodia >= @i_custodia1 or @i_custodia1 is null) 
        and (in_custodia <= @i_custodia2 or @i_custodia2 is null) 
        and (in_estado = @i_estado or @i_estado is null) 
        and (in_fecha_insp >= @i_fecha_insp1 or @i_fecha_insp1 is null) 
        and (in_fecha_insp <= @i_fecha_insp2 or @i_fecha_insp2 is null)
        and (in_inspector = @i_inspector or @i_inspector is null) 
        and ((in_tipo_cust > @i_tipo_cust1 or (in_tipo_cust = @i_tipo_cust1
            and in_custodia > @i_custodia3) or (in_tipo_cust = @i_tipo_cust1
            and in_custodia = @i_custodia3 and in_fecha_insp >@i_fecha_insp3)) 
            or @i_custodia3 is null)
        order by 2, 1, 4--in_tipo_cust, in_custodia, in_fecha_insp

        if @@rowcount = 0
        begin
            if @i_custodia is null /* Modo 0 */
               return 1
            else
               return 2
        end
        return 0
end 


if @i_operacion = 'Z'
begin
      set rowcount 20
      select distinct 'GARANTIA' = in_custodia, 
			 'TIPO' = in_tipo_cust,
             'DESC' = tc_descripcion,
             'FECHA' = convert(char(10),in_fecha_insp,@i_formato_fecha),
             'OFICIAL' = cg_oficial,
             'CLIENTE' = cg_ente,
             ' ' = cg_nombre,
             --'OFICIAL' = en_oficial,
             --'CLIENTE' = en_ente,
             --'' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
             'ESTADO' = in_estado, 
			 'INSPECTOR' = in_inspector
      from cu_inspeccion with(1),cu_custodia with(1), --cobis..cl_ente,
           cu_cliente_garantia, cu_tipo_custodia
      where in_filial = @i_filial
        and in_sucursal = @i_sucursal
        and in_codigo_externo = cu_codigo_externo
        and tc_tipo = cu_tipo
        and in_codigo_externo = cg_codigo_externo
        and (in_tipo_cust like @i_tipo_cust or @i_tipo_cust is null) 
        and (in_custodia >= @i_custodia1 or @i_custodia1 is null) 
        and (in_custodia <= @i_custodia2 or @i_custodia2 is null) 
        and (in_estado = @i_estado or @i_estado is null) 
        and (in_fecha_insp >= @i_fecha_insp1 or @i_fecha_insp1 is null)
        and (in_fecha_insp <= @i_fecha_insp2 or @i_fecha_insp2 is null)
        and (in_inspector = @i_inspector or @i_inspector is null) 
        and (cg_oficial >= @i_oficial1 or @i_oficial1 is null) 
      --and (en_oficial >= @i_oficial1 or @i_oficial1 is null) 
      --and (en_ente = cg_ente) 
        and cg_principal  = 'S' 
        and (cg_ente = @i_cliente or @i_cliente is null) 
      --and (en_ente = @i_cliente or @i_cliente is null) 
        and ((in_tipo_cust > @i_tipo_cust1 or (in_tipo_cust = @i_tipo_cust1
            and in_custodia > @i_custodia3) or (in_tipo_cust = @i_tipo_cust1
            and in_custodia = @i_custodia3 and in_fecha_insp >@i_fecha_insp3)) 
            or @i_custodia3 is null)
        order by 2, 1, 4 --in_tipo_cust, in_custodia, in_fecha_insp

        if @@rowcount = 0
        begin
            if @i_custodia is null /* Modo 0 */
               select @w_error  = 1901003
            else
               select @w_error  = 1901004

            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
        end
        return 0
end



if @i_operacion = 'N' --MVI 09/26/96 para consulta de garantias con novedades 
begin
      set rowcount 20

      select distinct 'GARANTIA' = in_custodia, 
			 'TIPO' = in_tipo_cust,
             'DESC' = tc_descripcion,
             'FECHA' = convert(char(10),in_fecha_insp,@i_formato_fecha),
             'VALOR' = cu_valor_actual,
             'OFICIAL' = cg_oficial,
             'CLIENTE' = cg_ente,
             ' ' = cg_nombre,
           --'OFICIAL' = en_oficial,
           --'CLIENTE' = en_ente,
           --'' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
             'ESTADO' = in_estado, 
			 'INSPECTOR' = in_inspector ,
             'NOVEDADES' = in_observaciones, 
             'COMENTARIO' = substring(in_instruccion,1,70)
      from cu_inspeccion with(1),cu_custodia with(1), --cobis..cl_ente,
           cu_cliente_garantia, cu_tipo_custodia
      where in_filial = @i_filial
        and in_sucursal = @i_sucursal
        and in_codigo_externo = cu_codigo_externo
        and tc_tipo = cu_tipo
        and in_codigo_externo = cg_codigo_externo
        and in_observaciones <> null
        and (in_tipo_cust like @i_tipo_cust or @i_tipo_cust is null)
        and (in_custodia >= @i_custodia1 or @i_custodia1 is null)
        and (in_custodia <= @i_custodia2 or @i_custodia2 is null)
        and (in_estado = @i_estado or @i_estado is null)
        and (in_fecha_insp >= @i_fecha_insp1 or @i_fecha_insp1 is null)
        and (in_fecha_insp <= @i_fecha_insp2 or @i_fecha_insp2 is null)
        and (in_inspector = @i_inspector or @i_inspector is null)
        and (cg_oficial >= @i_oficial1 or @i_oficial1 is null)
        and (cg_oficial <= @i_oficial2 or @i_oficial2 is null)
      --and (en_oficial >= @i_oficial1 or @i_oficial1 is null) 
      --and (en_oficial <= @i_oficial2 or @i_oficial2 is null)
      --and (en_ente = cg_ente) 
        and cg_principal = 'S'
        and (cg_ente = @i_cliente or @i_cliente is null)
      --and (en_ente = @i_cliente or @i_cliente is null)
        and ((in_tipo_cust > @i_tipo_cust1 or (in_tipo_cust = @i_tipo_cust1
            and in_custodia > @i_custodia3) or (in_tipo_cust = @i_tipo_cust1
            and in_custodia = @i_custodia3 and in_fecha_insp >@i_fecha_insp3)) 
            or @i_custodia3 is null)
        order by 2, 1, 4--in_tipo_cust, in_custodia, in_fecha_insp

        if @@rowcount = 0
        begin
            if @i_custodia is null /* Modo 0 */
               select @w_error  = 1901003
            else
               select @w_error  = 1901004

            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
        end
        return 0
end


if @i_operacion = 'C'
begin
   set rowcount 20
   select distinct 'GARANTIA'=in_custodia,
		  'TIPO'=in_tipo_cust,
          'VALOR FACTURA'=in_valor_fact,
          'FECHA'=convert(char(10),in_fecha_insp,101),
          'CLIENTE'=cg_ente, 
		  'CTA CLIEN'=cu_cta_inspeccion,
          'TCC'= cu_tipo_cta,
		  'INSP'=in_inspector,
		  'CTA INSP'=is_cta_inspector,
          'TCI'=is_tipo_cta,
		  'ESTADO'=in_estado_tramite 
   from cu_inspeccion with(1),cu_inspector, --cobis..cl_ente
        cu_custodia with(1),cu_cliente_garantia
   where in_filial         = @i_filial
     and in_sucursal       = @i_sucursal
     and in_estado_tramite = 'N' /* Aun No cobradas */
     and cu_filial         = @i_filial
     and cu_sucursal       = @i_sucursal
     and cu_tipo           = in_tipo_cust
     and cu_custodia       = in_custodia
     and cg_codigo_externo = cu_codigo_externo
   --and cg_ente           = en_ente
     and cg_principal      = 'S'
     and in_inspector      = is_inspector
     and in_valor_fact     <> 0
     and (((in_tipo_cust > @i_tipo_cust) 
          or (in_tipo_cust = @i_tipo_cust and in_custodia > @i_custodia))
          or @i_tipo_cust is null)
     order by 4--in_codigo_externo,in_fecha_insp

     if @@rowcount = 0
     begin
         return 1 
     end 

     return 0

end


if @i_operacion = 'T'
begin
    select @w_valor_total = sum(isnull(in_valor_fact,0))
    from cu_inspeccion
    where in_inspector = @i_inspector 
end


if @i_operacion = 'M'
begin
   set rowcount 20
   select distinct 'GARANTIA'=in_custodia,
		  'TIPO'=in_tipo_cust,
          'VALOR FACTURA'=in_valor_fact,
          'FECHA'=convert(char(10),in_fecha_insp,101),
          'CLIENTE'=cg_ente, 
		  'CTA CLIEN'=cu_cta_inspeccion,
          'TCC'= cu_tipo_cta,
		  'INSP'=in_inspector,
		  'CTA INSP'=is_cta_inspector,
          'TCI'=is_tipo_cta,
		  'ESTADO'=in_estado_tramite
   from cu_inspeccion with(1),cu_inspector, --cobis..cl_ente
        cu_custodia with(1),cu_cliente_garantia
   where in_filial         = @i_filial
     and in_sucursal       = @i_sucursal
     and in_estado_tramite = 'S' /*Cobradas */
     and cu_filial         = @i_filial
     and cu_sucursal       = @i_sucursal
     and cu_tipo           = in_tipo_cust
     and cu_custodia       = in_custodia
     and cg_codigo_externo = cu_codigo_externo
     --and cg_ente           = en_ente
     and cg_principal      = 'S'
     and in_inspector      = is_inspector
     and in_valor_fact     <> 0
     and (((in_tipo_cust > @i_tipo_cust) 
          or (in_tipo_cust = @i_tipo_cust and in_custodia > @i_custodia))
          or @i_tipo_cust is null)
     order by 4--in_codigo_externo,in_fecha_insp     

     if @@rowcount = 0
     begin
      return 1
     end 
     return 0
end


if @i_operacion = 'B'  --MVI 07/01/96 para el grid de prendas del inspector
begin
      set rowcount 20
         select 'GARANTIA' = pi_custodia, 
				'TIPO' = pi_tipo,
                'DESCRIPCION' = tc_descripcion,
                'CLIENTE' = cg_ente,
                'NOMBRE' =  cg_nombre,
               --'CLIENTE' = en_ente,
               --'NOMBRE' = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre,
                'PERIODICIDAD' = cu_periodicidad 
         from cu_control_inspector,cu_por_inspeccionar with(1),cu_custodia with(1),
              cu_tipo_custodia,cu_cliente_garantia
              --cobis..cl_ente
         where  pi_filial         = @i_filial
           and  pi_sucursal       = @i_sucursal
           and  ci_inspector      = @i_inspector
           and  ci_fenvio_carta   = @i_fecha_carta
           and  pi_inspector_asig = @i_inspector
           and  pi_codigo_externo = cu_codigo_externo
           and  pi_inspeccionado  = 'N'
           and  cu_inspeccionar   = 'S' 
           and  cu_periodicidad   <> 'N'
           and  tc_tipo           = pi_tipo
           and  cg_codigo_externo = cu_codigo_externo
           and  cg_principal      = 'S'
           --and  en_ente           = cg_ente
           and ((pi_tipo > @i_tipo_cust1) or   --OJO REVISAR MVI
                (pi_tipo = @i_tipo_cust1 and pi_custodia > @i_custodia1) or
                (@i_tipo_cust1 is null))
         order by pi_tipo, pi_custodia

         if @@rowcount = 0
         begin
            return 1 
         end 
         return 0
end


if @i_operacion = 'E'
begin
  begin tran
     if exists (select 1 from cu_inspeccion
                 where in_filial         = @i_filial
                   and in_sucursal       = @i_sucursal
                   and in_custodia       = @i_custodia
                   and in_tipo_cust      = @i_tipo_cust
                   and in_fecha_insp     = @i_fecha_insp
                   and in_estado_tramite = 'N')

         update cu_inspeccion
         set in_estado_tramite = 'S'
         where in_filial         = @i_filial
           and in_sucursal       = @i_sucursal
           and in_custodia       = @i_custodia
           and in_tipo_cust      = @i_tipo_cust
           and in_fecha_insp     = @i_fecha_insp
     else
     begin
         select @w_error = 1907002
         goto error
     end

   commit tran

end

return 0


error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1
go