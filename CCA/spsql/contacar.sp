/************************************************************************/
/*   Nombre Fisico:        contacar.sp                                  */
/*   Nombre Logico:        sp_conta_car                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                                PROPOSITO                             */
/*   Saldos de Cartera por diferentes conceptos para Herramienta de     */
/*   Cuadre Contable.  Tabla cob_ccontable..cco_boc.                    */
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*   07/20/2003    Julio C Quintero      Ajuste Cuentas Dinamicas y     */
/*                                       Control de Errores             */
/*  ene/05/2006    Elcira Pelaez         Redondeo a 2 decimales para HC */
/*                                       def. 4456                      */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_op_calificacion*/
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conta_car')
   drop proc sp_conta_car
go

create proc sp_conta_car
   @i_filial   int,
   @i_fecha    datetime,
   @i_proceso  int,
   @i_reproceso_mensual char = 'N'
as
declare
   @w_op_banco          cuenta,
   @w_op_oficina        int,
   @w_op_moneda         int,
   @w_op_toperacion     varchar(10),
   @w_am_concepto       varchar(10),
   @w_op_estado         int,
   @w_co_codigo         int,
   @w_dp_cuenta         varchar(60),
   @w_op_clase          char,
   @w_op_destino        varchar(10),
   @w_op_calificacion   catalogo,
   @w_op_gar_admisible  char,
   @w_op_tipo_linea     varchar(10),
   @w_dp_debcred        char,
   @w_dp_area           varchar(10),
   @w_adicional         varchar(255),
   @w_moneda_conta      int,
   @w_op_operacion      int,
   @w_op_estado_cas     char(1),
   --
   @w_cuenta_aux        varchar(60),
   @w_evitar_asiento    char,
   @w_resultado         varchar(30),
   @w_cuenta_final      varchar(60),
   @w_trama             varchar(60),
   @w_clave             varchar(60),
   @w_anexo             varchar(255),
   @w_categoria         catalogo,
   @w_subtipo_linea     catalogo,
   @w_ascii             int,
   @w_pos               int,
   --
   @w_valor_nal         money,
   @w_valor_ext         money,
   @w_error             int,
   @w_re_area           smallint,
   @w_tran              varchar(10),
   @w_parametro_valido  int,
   @w_cuenta_valida     char(1),
   @w_sp_name           descripcion,
   @w_oficina_central   int,
   @w_origen_dest       char(1),
   @w_ofconta           smallint,
   @w_ult_codvalor      int,
   @w_codvalor_resuelto char(1),
   @w_num_dec           int,
   @w_op_sector         catalogo,
   @w_cod_producto      tinyint,
   @w_parametro         varchar(24),
   @w_clase_cust        varchar(1),
   @w_mensaje           varchar(255),
   
   -- PARALELISMO
   @p_operacion_ini  int,
   @p_operacion_fin  int,
   @p_proceso        int,
   @p_programa       catalogo,
   @p_total_oper     int,
   @p_estado         char(1),
   @p_ult_update     datetime,
   @p_cont_operacion int,
   @p_tiempo_update  int,
   @w_rowcount       int
begin
   --PRINT 'CONTACAR: 1'
   select @w_num_dec      = 2,
          @w_cod_producto = 7
   
   begin tran
   create table #tmp_error_hc
   (er_codvalor     int,
    er_fecha_proc   datetime,
    er_error        int,
    er_usuario      login,
    er_tran         int,
    er_cuenta       cuenta,
    er_descripcion  varchar(255),
    er_anexo        varchar(255)
   )
   commit tran
   
   select @p_programa      = 'cacontac',
          @p_proceso       = @i_proceso, -- SOLO POR MANTENER EL ESTANDAR DEL NOMBRE DE VARIABLES DEL PARALELO
          @p_ult_update    = getdate(),
          @p_tiempo_update = 15
   
   --PRINT '@p_proceso ' + CAST(@p_proceso AS VARCHAR)
   
   if @p_proceso is not null
   begin
       declare @cont1 integer
       select @cont1 = count(1) from ca_paralelo_tmp(nolock)
       where  programa = @p_programa
       and    proceso  = @p_proceso


      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
       update ca_paralelo_tmp 
       set    estado     = 'P',
              spid       = @@spid,
              hora       = getdate(),
              hostprocess = master..sysprocesses.hostprocess
       from   master..sysprocesses
       where  programa = @p_programa
        and    proceso  = @p_proceso
        and    master..sysprocesses.spid = @@spid

       SET TRANSACTION ISOLATION LEVEL SNAPSHOT

   end
    if @p_proceso is not null
    begin
       select @p_operacion_ini  = operacion_ini,
              @p_operacion_fin  = operacion_fin,
              @p_estado         = estado,
              @p_cont_operacion = isnull(procesados, @p_operacion_fin - @p_operacion_ini)
       from   ca_paralelo_tmp (nolock)
       where  programa = @p_programa
       and    proceso  = @p_proceso
    end
    ELSE
       select @p_estado = 'P'
   
   select @w_tran = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'TRCOB'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0
      select @w_tran = 'PAG'
   
   begin tran
   create table #tmp_asiento_hc
   (
      ah_cuenta        cuenta,
      ah_oficina       smallint,
      ah_area          smallint,
      ah_moneda        smallint,
      ah_val_opera_mn  money,
      ah_val_opera_me  money,
      ah_operacion_mod cuenta,
      ah_adicional     varchar(255),
      ah_codvalor      int
   )
   commit tran
   
   select @w_oficina_central = pa_int
   from   cobis..cl_parametro
   where  pa_nemonico = 'OFC'
   and    pa_producto = 'CON'
   set transaction isolation level read uncommitted

   -- VARIABLES DE TRABAJO
   select @w_sp_name  = 'contacar.sp'
   
   BEGIN TRAN
   -- LIMPIAR TABLA TEMPORAL
   
   create table #cb_relparam
   (re_empresa      tinyint     NOT NULL,
    re_parametro    varchar(10) NOT NULL,
    re_clave        varchar(20) NOT NULL,
    re_substring    varchar(20) NOT NULL,
    re_producto     tinyint     NULL,
    re_tipo_area    varchar(10) NULL,
    re_origen_dest  char(1)     NULL)
   
   COMMIT TRAN
   
   insert into #cb_relparam
   select re_empresa, re_parametro,
          re_clave, 
          re_substring, re_producto,
          re_tipo_area, re_origen_dest
   from   cob_conta..cb_relparam
   where  re_producto = @w_cod_producto
   
--   create index #cb_relparam_Key on #cb_relparam (re_empresa, re_parametro, re_clave)   
   create index cb_relparam_Key on #cb_relparam (re_empresa, re_parametro, re_clave)   
      
   select @p_cont_operacion = 0
   -- CURSOR DE OBLIGACIONES
   if @i_reproceso_mensual = 'S'
   declare
      cOper cursor
      for   select oh_banco,         oh_oficina,       oh_moneda,
                   oh_toperacion,    oh_clase,         oh_destino,
                   oh_calificacion,  oh_gar_admisible, oh_tipo_linea,
                   oh_operacion,     oh_estado
            from   ca_operacion_hc o
            where  oh_operacion between @p_operacion_ini and @p_operacion_fin
            and    oh_fecha = @i_fecha
            and    exists(select 1
                          from   ca_saldos_cartera
                          where  sc_operacion = o.oh_operacion
                          and    sc_estado_con != 'C')
            for    read only
   else
   begin
   if @p_proceso is not null 
    begin
      --PRINT 'OPERACION INI: ' + CAST(@p_operacion_ini AS VARCHAR) + ' ' + CAST(@p_operacion_fin AS VARCHAR)
      declare
      cOper cursor
      for   select op_banco,         op_oficina,       op_moneda,
                   op_toperacion,    op_clase,         op_destino,
                   isnull(op_calificacion, 'A'),  isnull(op_gar_admisible, 'N'), op_tipo_linea,
                   op_operacion,     op_estado,        op_sector
            from   ca_operacion o
            where  op_operacion between @p_operacion_ini and @p_operacion_fin
            and    exists(select 1
                          from   ca_saldos_cartera
                          where  sc_operacion = o.op_operacion
                          and    sc_estado_con != 'C')
            for    read only
    end
    ELSE
    begin
      select @p_estado = 'P'
      declare
      cOper cursor
      for   select op_banco,         op_oficina,       op_moneda,
                   op_toperacion,    op_clase,         op_destino,
                   isnull(op_calificacion, 'A'),  isnull(op_gar_admisible, 'N'), op_tipo_linea,
                   op_operacion,     op_estado,        op_sector
            from   ca_operacion o
            where  exists(select 1
                          from   ca_saldos_cartera
                          where  sc_operacion = o.op_operacion
                          and    sc_estado_con != 'C')
            ---and           op_banco in ('170020000079682','140030000131921')
            for    read only

    end

   end
   if @p_proceso is not null 
   begin
      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      BEGIN TRAN
      
      update ca_paralelo_tmp
      set    estado     = 'P',
             spid       = @@spid,
             hora       = getdate(),
             hostprocess = master..sysprocesses.hostprocess,
             procesados  = @p_cont_operacion
      from   master..sysprocesses
      where  programa = @p_programa
      and    proceso  = @p_proceso
      and    master..sysprocesses.spid = @@spid
      
      COMMIT TRAN
 
      SET TRANSACTION ISOLATION LEVEL SNAPSHOT

   end
   
   open cOper
   
   fetch cOper
   into  @w_op_banco,         @w_op_oficina,        @w_op_moneda,
         @w_op_toperacion,    @w_op_clase,          @w_op_destino,
         @w_op_calificacion,  @w_op_gar_admisible,  @w_op_tipo_linea,
         @w_op_operacion,     @w_op_estado,         @w_op_sector
   
--   while (@@fetch_status not in (-1,0) and (@p_estado = 'P'))
   while (@@fetch_status = 0) and (@p_estado = 'P')
   begin
      -- CONTROL DE EJECUCION DE PARALELISMO
      if @p_proceso is not null
      begin
         -- ACTUALIZAR EL NUMERO DE REGISTROS PROCESADOS
         select @p_cont_operacion = @p_cont_operacion + 1
         
         -- ACTUALIZAR EL PROCESO CADA MINUTO
         if datediff(ss, @p_ult_update, getdate()) > @p_tiempo_update
         begin
             select @p_ult_update = getdate()
             SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
             BEGIN TRAN
            
            update ca_paralelo_tmp
            set    hora   = getdate(),
                   procesados = @p_cont_operacion
            where  programa = @p_programa
            and    proceso = @p_proceso
            
            -- AVERIGUAR EL ESTADO DEL PROCESO
            select @p_estado = estado
            from   ca_paralelo_tmp
            where  programa = @p_programa
            and    proceso = @p_proceso
            
            COMMIT TRAN
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT
         end
      end
      
      if @w_op_estado = 4
         select @w_op_estado_cas = '2'
      else
         select @w_op_estado_cas = '1'
      
      -- PARA CADA OBLIGACION RESOLVER EL PERFIL BOC
      select @w_op_toperacion = rtrim(@w_op_toperacion),
             @w_op_destino    = rtrim(@w_op_destino),
             @w_op_tipo_linea = rtrim(@w_op_tipo_linea)
      
      if @w_op_gar_admisible = 'N'
         select @w_op_gar_admisible = 'O'
      else
         select @w_op_gar_admisible = 'I'
      
      if @w_op_moneda = 2
         select @w_moneda_conta = 0
      else
         select @w_moneda_conta = @w_op_moneda
      
      -- BORRA LOS ASIENTOS TEMPORALES
      delete #tmp_asiento_hc
      
      -- BORRA LOS ERRORES DE ESTA OBLIGACION
      delete #tmp_error_hc
      
      select @w_ult_codvalor = -1
      -- LLENAR LOS ASIENTOS TEMPORALES
      declare
         cPerfil cursor
         for select sc_concepto,     sc_codvalor, dp_cuenta,
                    sc_valor,        dp_debcred,  dp_area,
                    dp_origen_dest,  sc_valor_me, dt_categoria,
                    dt_subtipo_linea
             from   ca_saldos_cartera,
                    cob_conta..cb_det_perfil noholdlock,
                    ca_default_toperacion
             where  sc_operacion = @w_op_operacion
             and    dp_empresa    = @i_filial
             and    dp_producto   = @w_cod_producto
             and    dp_perfil     = sc_perfil
             and    dp_codval     = sc_codvalor
             and    dt_toperacion = @w_op_toperacion
             and    dt_moneda     = @w_op_moneda
             and    sc_estado_con = 'I'
             order  by sc_codvalor
             for    read only
      
      open cPerfil
      
      fetch cPerfil
      into  @w_am_concepto,   @w_co_codigo,  @w_dp_cuenta,
            @w_valor_nal,     @w_dp_debcred, @w_dp_area,
            @w_origen_dest,   @w_valor_ext,  @w_categoria,
            @w_subtipo_linea
      
--      while (@@fetch_status not in (-1,0))
      while (@@fetch_status = 0)
      begin
         if @w_ult_codvalor != @w_co_codigo
         begin
            select @w_codvalor_resuelto = 'N',
                   @w_ult_codvalor      = @w_co_codigo
         end
         ELSE -- EL MISMO codvalor
         begin
            if @w_codvalor_resuelto = 'S' and @w_am_concepto = 'CAP'-- PASAR AL SIGUIENTE codvalor
            begin
               fetch cPerfil
               into  @w_am_concepto,   @w_co_codigo,  @w_dp_cuenta,
                     @w_valor_nal,     @w_dp_debcred, @w_dp_area,
                     @w_origen_dest,   @w_valor_ext,  @w_categoria,
                     @w_subtipo_linea
               
               continue
            end
         end
         
         select @w_am_concepto   = rtrim(@w_am_concepto)
         
         select @w_valor_nal = round(@w_valor_nal,@w_num_dec)
         select @w_valor_ext = round(@w_valor_ext,@w_num_dec)
         
---------
         -- RESOLUCION DE LA CUENTA DINAMICA
         select @w_cuenta_aux = @w_dp_cuenta
         select @w_pos = charindex('.', @w_cuenta_aux)
         
         if @w_pos = 0 -- NO TIENE QUE RESOLVER PARAMETROS LA CUENTA NO ES DINAMICA
         begin
            select @w_cuenta_final = @w_dp_cuenta,
                   @w_cuenta_valida  = 'S'
         end
         ELSE
         begin
            select @w_cuenta_valida = 'S'
            select @w_cuenta_final = ''
            
            while 0 = 0 -- RESOLUCION DE LA CUENTA
            begin
               -- ELIMINAR PUNTOS INICIALES
               while @w_pos = 1
               begin
                  select @w_cuenta_aux = substring (@w_cuenta_aux, 2, datalength(@w_cuenta_aux) - 1)
                  select @w_pos = charindex('.', @w_cuenta_aux)
               end
               
               -- AISLAR SIGUIENTE PARAMETRO DEL RESTO DE LA CUENTA
               if @w_pos > 0 --existe al menos un parametro
               begin
                  select @w_trama = substring (@w_cuenta_aux, 1, @w_pos-1)
                  select @w_cuenta_aux = substring (@w_cuenta_aux, @w_pos+1, datalength(@w_cuenta_aux) - @w_pos)
                  select @w_pos = charindex('.', @w_cuenta_aux)
               end
               ELSE
               begin
                  select @w_trama = @w_cuenta_aux
                  select @w_cuenta_aux = ''
               end
               
               -- CONDICION DE SALIDA DEL LAZO
               if @w_trama = '' 
                  break
               
               -- VERIFICAR SI LA TRAMA ES PARTE FIJA O PARAMETRO
               select @w_ascii = ascii(substring(@w_trama, 1, 1))
               
               if @w_ascii >= 48 and @w_ascii <= 57 --NUMERICO,PARTE FIJA
               begin
                  select @w_cuenta_final = @w_cuenta_final + @w_trama 
               end
               ELSE
               begin  --LETRA, LA TRAMA ES UN PARAMETRO

				   select @w_resultado = ''

				   select @w_parametro = @w_trama


                   if @w_op_gar_admisible = 'S' 
                      select @w_clase_cust = 'I'
                   else 
                      select @w_clase_cust = 'O'
       
                  print '---->contacar.sp @w_parametro: ' + cast(@w_parametro as varchar)

				   exec @w_error     = sp_cuenta --_hc
				   @i_debug          = 'S',
				   @i_parametro      = @w_parametro,   --@w_dp_cuenta, 
				   @i_moneda         = @w_op_moneda,
				   @i_sector         = @w_op_sector,
				   @i_gar_admisible  = @w_clase_cust,
				   @i_calificacion   = @w_op_calificacion,
				   @i_clase_cart     = @w_op_clase,
				   @i_clase_cust     = @w_clase_cust,
				   @i_producto       = @w_cod_producto,     
				   @i_concepto       = @w_am_concepto,
				   @i_estado         = @w_op_estado,
				   @i_categoria      = @w_categoria,
				   @o_cuenta         = @w_resultado      out, 
				   @o_evitar_asiento = @w_evitar_asiento out, 
				   @o_msg            = @w_mensaje        out

				   if @w_error != 0
				   begin
                      print '---->contacar.sp @w_error: ' + cast(@w_error as varchar)
					  close cPerfil
					  deallocate cPerfil
					  goto SIGUIENTE_CUENTA
				   end

                  print '---->contacar.sp @w_resultado: ' + cast(@w_resultado as varchar)
                  if @w_evitar_asiento = 'S'
                  begin
                     select @w_parametro_valido = 0
                  end
                  else
                  begin
                     select @w_parametro_valido = 1
                  end
                  
                  if @w_parametro_valido = 0 -- ERROR GRAVE, EL PARAMETRO NO HA SIDO PROGRAMADO
                  begin
                      select @w_cuenta_valida = 'N'
                      select @w_error = 710444
                      select @w_anexo = @w_op_toperacion
                                      + ' ' + @w_am_concepto
                                      + ' Parte Variable: ' + @w_trama
                                      + ' Valor: ' + @w_resultado 
                     
                     insert into ca_errorlog
                           (er_fecha_proc,  er_error,
                            er_usuario,     er_tran,        er_cuenta,
                            er_descripcion,                 er_anexo)
                     values(
                            @i_fecha,       710444,
                            'CUADRECAR',    @w_co_codigo,    @w_op_banco,
                            'Parametro no Programado',      @w_anexo)
                     
                     goto SIGUIENTE_CUENTA
                  end

                   
                   

				   select @w_cuenta_final = @w_cuenta_final + @w_resultado


               end  -- CONDICION NUMERICO,PARTE FIJA
            end -- FIN WHILE 0=0
         end -- FIN CUENTA DINAMICA
         
         select @w_cuenta_final = ltrim(@w_cuenta_final)

         print '---->contacar.sp @w_cuenta_final: ' + cast(@w_cuenta_final as varchar)
         
         -- TODO SE PUDO RESOLVER, INSERTAR LA CUENTA EN ASIENTO TEMPORAL
         if @w_cuenta_valida = 'S'
         begin
            -- SI LA CUENTA ES VALIDA NO INTENTARA MAS
            select @w_codvalor_resuelto = 'S'
            
            -- SE BORRAN LOS ERRORES DEL CODIGO VALOR
            -- LO QUE SE PUEDE RESOLVER SE BORRA DE LOS ERRORES
            delete #tmp_error_hc
            where  er_codvalor = @w_co_codigo
            
            -- GRABAR EL ASIENTO TEMPORAL
            if exists(select 1 from #tmp_asiento_hc
                      where ah_cuenta = @w_cuenta_final)
            begin
               update #tmp_asiento_hc
               set    ah_val_opera_mn = ah_val_opera_mn + @w_valor_nal,
                      ah_val_opera_me = ah_val_opera_me + @w_valor_ext
               where  ah_cuenta = @w_cuenta_final
            end
            ELSE
            begin
               select @w_re_area = 0
               
               select @w_re_area = ta_area
               from   cob_conta..cb_tipo_area
               where  ta_empresa  = @i_filial
               and    ta_producto = @w_cod_producto
               and    ta_tiparea  = @w_dp_area
               set transaction isolation level read uncommitted
               
               if @w_origen_dest = 'C'
                  select @w_ofconta = @w_oficina_central
               else
               begin
                  select @w_ofconta = @w_op_oficina
                  
                  select @w_ofconta = re_ofconta
                  from   cob_conta..cb_relofi
                  where  re_filial  = @i_filial
                  and    re_empresa = @i_filial
                  and    re_ofadmin = @w_ofconta
               end
               
               select @w_adicional = 'lin:' + @w_op_toperacion
               select @w_adicional = @w_adicional + ' cto:' + @w_am_concepto
               select @w_adicional = @w_adicional + ' codv:' + convert(varchar, @w_co_codigo)
               select @w_adicional = @w_adicional + ' orig:' + rtrim(@w_dp_cuenta)
               select @w_adicional = @w_adicional + ' clase: ' + rtrim(@w_op_clase)
               select @w_adicional = @w_adicional + ' dest: ' + rtrim(@w_op_destino)
               select @w_adicional = @w_adicional + ' calf: ' + @w_op_calificacion
               select @w_adicional = @w_adicional + ' gar: ' + rtrim(@w_op_gar_admisible)
               select @w_adicional = @w_adicional + ' tlin: ' + rtrim(@w_op_tipo_linea)
               
               insert into #tmp_asiento_hc
                     (ah_cuenta,        ah_oficina,
                      ah_area,         ah_moneda,        ah_val_opera_mn,
                      ah_val_opera_me, ah_operacion_mod, ah_adicional,
                      ah_codvalor)
               values(@w_cuenta_final,  @w_ofconta,
                      @w_re_area,      @w_moneda_conta,  @w_valor_nal,
                      @w_valor_ext,    @w_op_banco,      @w_adicional,
                      @w_co_codigo)
            end
         end
         
SIGUIENTE_CUENTA:
         fetch cPerfil
         into  @w_am_concepto,   @w_co_codigo,  @w_dp_cuenta,
               @w_valor_nal,     @w_dp_debcred, @w_dp_area,
               @w_origen_dest,   @w_valor_ext,  @w_categoria,
               @w_subtipo_linea
      end
      
VERIFICACION_ERRORES:
      close cPerfil
      deallocate cPerfil
      
      -- SI HAY REGISTROS EN LA TABLA TEMPORAL DE ERRORES  => NO TODO SE PUDO RESOLVER PARA LA OBLIGACION
      while @@trancount > 0 COMMIT TRAN -- ASEGURAR TODO LO ESCRITO, EN TODO CASO SON SOLO TABLAS TEMPORALES
      
      if exists(select 1 from #tmp_error_hc)
      begin -- SI HAY ERRORES NO ES VALIDA LA OBLIGACION
         BEGIN TRAN
         insert into ca_errorlog
               (er_fecha_proc,  er_error,
                er_usuario,     er_tran,        er_cuenta,
                er_descripcion,                 er_anexo)
         select er_fecha_proc,  er_error,
                er_usuario,     er_tran,        er_cuenta,
                er_descripcion,                 er_anexo
         from   #tmp_error_hc
         COMMIT
         
         goto SIGUIENTE_OPER
      end
      
      -- LLEVAR LOS DATOS A cob_ccontable
      declare
         cCuentas cursor
         for select ah_cuenta,       ah_oficina,       ah_codvalor,
                    ah_area,         ah_moneda,        ah_val_opera_mn,
                    ah_val_opera_me, ah_operacion_mod, ah_adicional
             from   #tmp_asiento_hc
             for    read only
         
      BEGIN TRAN -- TODA LA OBLIGACION
      
      open cCuentas
      
      fetch cCuentas
      into  @w_cuenta_final,  @w_ofconta,       @w_co_codigo,
            @w_re_area,       @w_moneda_conta,  @w_valor_nal,
            @w_valor_ext,     @w_op_banco,      @w_adicional
      
--      while (@@fetch_status not in (-1,0))
      while (@@fetch_status = 0)
      begin

         exec @w_error = cob_ccontable..sp_ing_opera_det
              @t_trn           = 60032,
              @i_operacion     = 'I',
              @i_empresa       = @i_filial,
              @i_producto      = @w_cod_producto,
              @i_fecha         = @i_fecha,
              @i_cuenta        = @w_cuenta_final,
              @i_oficina       = @w_ofconta,
              @i_area          = @w_re_area,
              @i_moneda        = @w_moneda_conta,
              @i_val_opera_mn  = @w_valor_nal,
              @i_val_opera_me  = @w_valor_ext,
              @i_tipo          = 'S',
              @i_operacion_mod = @w_op_banco,
              @i_adicional     = @w_adicional
         
         if @w_error != 0 -- ERROR GRAVE
         begin
            while @@trancount > 0 ROLLBACK TRAN
            
            select @w_anexo = 'EMP: ' + convert(varchar(4), @i_filial)
            select @w_anexo = @w_anexo + '  OFI: ' + convert(varchar(4), @w_ofconta)
            select @w_anexo = @w_anexo + '  CUENTA : >' + @w_cuenta_final + '<'
            select @w_anexo = @w_anexo + '  AREA : ' + convert(varchar(6), @w_re_area)
            select @w_anexo = @w_anexo + '  MONEDA : ' + convert(varchar(3), @w_op_moneda)
            select @w_anexo = @w_anexo + '  VALOR : ' + convert(varchar(30), @w_valor_nal)
            select @w_anexo = @w_anexo + '  OBLIG : ' + @w_op_banco
            
            -- GRABAR EL ERROR DE CONTABLE
            exec sp_errorlog 
                 @i_fecha     = @i_fecha,
                 @i_error     = @w_error,
                 @i_usuario   = 'CUADRECAR',
                 @i_tran      = 7000,
                 @i_tran_name = @w_sp_name,
                 @i_rollback  = 'S',
                 @i_cuenta    = @w_op_banco,
                 @i_anexo     = @w_anexo
            
            update ca_saldos_cartera
            set    sc_estado_con = 'E'
            where  sc_operacion = @w_op_operacion
            and    sc_codvalor  > 0
            
            -- CERRAR CURSOR
            close cCuentas
            deallocate cCuentas
            
            -- Y PASAR A LA SIGUIENTE OBLIGACION
            goto SIGUIENTE_OPER
         end         
         
         -- SIGUIENTE CUENTA
         fetch cCuentas
         into  @w_cuenta_final,  @w_ofconta,       @w_co_codigo,
               @w_re_area,       @w_moneda_conta,  @w_valor_nal,
               @w_valor_ext,     @w_op_banco,      @w_adicional
      end
      
      -- TODO OK PARA LA OBLIGACION
      update ca_saldos_cartera
      set    sc_estado_con = 'C'
      where  sc_operacion = @w_op_operacion
      and    sc_codvalor  > 0
      
      COMMIT TRAN
      
      close cCuentas
      deallocate cCuentas
      
SIGUIENTE_OPER:
      delete #tmp_asiento_hc
      
      fetch cOper
      into  @w_op_banco,         @w_op_oficina,        @w_op_moneda,
            @w_op_toperacion,    @w_op_clase,          @w_op_destino,
            @w_op_calificacion,  @w_op_gar_admisible,  @w_op_tipo_linea,
            @w_op_operacion,     @w_op_estado,         @w_op_sector
   end
   
   close cOper
   deallocate cOper
   ----------------------------------------------
   -- BUSCAR EL PERFIL CORRECTO
   
   if @p_proceso is not null
   begin
       SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
       BEGIN TRAN  
       
       update ca_paralelo_tmp
       set    estado = 'T',
             procesados = @p_cont_operacion
       where  programa = @p_programa
       and    proceso = @p_proceso
      
       COMMIT TRAN
  
       SET TRANSACTION ISOLATION LEVEL SNAPSHOT
   end
   
end

return 0                                                                                                                   
go
