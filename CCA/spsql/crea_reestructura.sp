/************************************************************************/
/*   NOMBRE LOGICO:      crea_reestructura.sp	                        */
/*   NOMBRE FISICO:      sp_crea_reestructura                           */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Patricio Narvaez                               */
/*   FECHA DE ESCRITURA: Octubre 2020                                   */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                             PROPOSITO                                */
/*  Crea la operacion a reestructuracion en temporales y recalcula la   */
/*  operacion                                                           */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*     FECHA           AUTOR           RAZON                            */
/*  Oct/2020    P. Narvaez     Reestructura desde Cartera de operaciones*/
/*  Ene/2021    P. Narvaez     Tipo Reestructura y Tipo Renovacion      */
/*  Nov/2021    K. Rodriguez   Ajustes diferimiento de préstamos        */
/*  May/2022    K. Rodriguez   Ajustes mensajes error (Internacionaliz.)*/
/*  Jun/2022    G. Fernández   Corrección de mensajes de error          */
/*  Ago/2022    G. Fernández   Validación para actualizar valores de    */
/*                             reestructuración                         */
/*  May/2023    K. Rodriguez   S814865 Genera tabla amortiz. con tipo de*/
/*                             plazo igual al tipo dividendo            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crea_reestructura')
   drop proc sp_crea_reestructura
go

create proc sp_crea_reestructura ( 
   @s_user                 login,
   @s_term                 varchar(30), 
   @s_date                 datetime,
   @s_ofi                  smallint,
   @s_sesn                 int         = null,
   @s_ssn                  int         = null,
   @s_srv			         varchar(30) = NULL,
   @s_lsrv			         varchar(30) = NULL, 
   @i_operacion            char(2)     = null,
   @i_operacionesA         varchar(500)= '',   --Operaciones a reestructurar, incluida la operacion final
   @i_operacionesB         varchar(500)= '',
   @i_operacionesC         varchar(500)= '',
   @i_operacionesD         varchar(500)= '',
   @i_banco                cuenta,             --Operacion base o final que agrupa las reestructuras
   @i_saldo_reest          money       = 0,
   @i_debug                char(1)     = 'N',
   @i_tipo_reest           char(1)     = 'E' --null
)
as
declare
@w_sp_name        varchar(30),
@w_return         int,
@w_operaciones    varchar(8000),
@w_k              smallint,
@w_banco          cuenta,
@w_re_banco       cuenta,
@w_largo_trama    smallint,
@w_sc             char(1),
@w_saldo          money,
@w_operacionca    int,
@w_tdividendo     catalogo,
@w_re_operacionca int, 
@w_num_dec        tinyint,
@w_moneda         tinyint,
@w_moneda_n       tinyint,
@w_num_dec_mn     tinyint,
@w_operacion_base char(1),
@w_div_vigente    int,
@w_max_div        int,
@w_plazo_restante int,
@w_tramite        int,
@w_deudor         int,
@w_fpago_reest    catalogo,
@w_fecha_ult_proceso datetime,
@w_re_fecha_ult_proceso datetime,
@w_fecha_ini_nueva   datetime,
@w_oficial           smallint,
@w_sector            catalogo,
@w_ciudad            int,
@w_toperacion        catalogo,
@w_tplazo            catalogo,
@w_destino           catalogo,
@w_ente              int,
@w_clase             catalogo,
@w_saldo_reest       money,
@w_saldo_reest_tmp   money,
@w_tramite_opfinal   int,
@w_re_saldo          money,
@w_re_moneda         tinyint,
@w_cuenta_puente     catalogo, 
@w_est_vigente       tinyint,
@w_est_vencido       tinyint,
@w_desc_estado       varchar(30),
@w_monto_base        money,
@w_estado            tinyint,
@w_msg_error         varchar(132),
@w_monto_cursor      money,
@w_secuencial_ing    int,
@w_saldo_acum        money,
@w_est_cancelado     tinyint,
@w_secuencial_rest   int,
@w_periodo           tinyint,
@w_factor            float,
@w_rubro_cap         catalogo,
@w_estado_original   tinyint,
@w_estado_final      tinyint,
@w_concepto          catalogo,
@w_monto             money,
@w_monto_mn          money,
@w_cotizacion        float,
@w_codval_ant        int,
@w_codval_fin        int,
@w_comentario        varchar(50),
@w_tipo_reduccion    char(1),
@w_op_lin_credito    cuenta,
@w_monto_utilizado   money,
@w_naturaleza        char(1),
@w_opcion            char(1),
@w_reajustable       char(1),
@w_fecha_reajuste    datetime,
@w_id                int,
@w_rubro             catalogo,
@w_tipo_saldo        char(1),
@w_est_novigente     tinyint,
@w_est_credito       tinyint,
@w_saldo_op_final    money,
@w_cat1              float,
@w_tir               float,
@w_tea               float,
@w_reestructurar      char(1)

select 
@w_sp_name       = 'sp_crea_reestructura',
@w_est_vigente   = 1,
@w_est_vencido   = 2,
@w_est_cancelado = 3,
@w_est_novigente = 0,
@w_est_credito   = 99,
@w_return        = 0

select @w_rubro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'



--Guardar temporalmente las operaciones a renovar y calcular la operacion final con el nuevo saldo en tablas temporales,
--para que esta se actualizada desde el frontend similar una actualizacion de operaciones
if @i_operacion = 'T'
begin   
   delete ca_op_renovar_tmp
   where ot_user = @s_user
   and   ot_term = @s_term

   select @w_fecha_ult_proceso = op_fecha_ult_proceso
   from ca_operacion
   where op_banco = @i_banco  --Operacion final en temporales modificada desde el FrontEnd

   select @w_sc = ','
   select @w_operaciones = @i_operacionesA + @i_operacionesB + @i_operacionesC + @i_operacionesD
   select @w_largo_trama = len(@w_operaciones)   

   begin tran
   
   if @w_largo_trama > 0
   begin
      select @w_k           = charindex (@w_sc, @w_operaciones)
      while @w_k > 0 
      begin
         select @w_banco       = substring(@w_operaciones, 1, @w_k - 1)
         select @w_operaciones = substring(@w_operaciones, @w_k+1, @w_largo_trama)
         select @w_k  = charindex (@w_sc, @w_operaciones)

         select @w_tipo_saldo  = substring(@w_operaciones, 1, @w_k - 1)
         select @w_operaciones = substring(@w_operaciones, @w_k+1, @w_largo_trama)
         select @w_k  = charindex (@w_sc, @w_operaciones)

         select @w_saldo = 0
                  
         select 
         @w_operacionca          = op_operacion,
         @w_estado               = op_estado,
         @w_desc_estado          = es_descripcion,
         @w_re_fecha_ult_proceso = op_fecha_ult_proceso
         from ca_operacion, ca_estado
         where op_banco = @w_banco
         and   op_estado = es_codigo

         if @i_debug = 'S' print 'Operacion: ' + @w_banco

         if @w_estado in ( @w_est_novigente, @w_est_credito)
         begin
           --print '[sp_crea_reestructura] La operacion a reestructurar ' + @w_banco + ' tiene un estado no permitido ' + @w_desc_estado
           select @w_return = 725165 -- La operacion a diferir o reestructurar tiene un estado no permitido
		   goto ERROR
         end

         if @w_fecha_ult_proceso <> @w_re_fecha_ult_proceso
         begin
           --print '[sp_crea_reestructura] Fecha valor de la operacion ' + @w_banco + ' no coincide con la fecha de reestructura'
           select @w_return = 711079 -- 'La fecha valor de la(s) operacion(es) a cancelar no coincide con las fecha de la reestructura'
		   goto ERROR
         end
         /*
         N: Saldo Capital
         S: Saldo Capital + Interes
         T. Saldo Capital + Interes + Otros Saldos
         X: No se reestructura ningun saldo
         */
		 
		 if(@i_tipo_reest = 'E')
		 begin
		 
		    if @w_tipo_saldo in ('N','S')
            begin
               select @w_saldo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
               from ca_rubro_op, ca_amortizacion
               where ro_operacion = @w_operacionca
               and   am_estado    <> @w_est_cancelado
               and   ro_operacion = am_operacion
               and   ro_concepto  = am_concepto
               and   (@w_tipo_saldo <> 'N' or ro_tipo_rubro <> 'C')
               and   (@w_tipo_saldo <> 'S' or ro_tipo_rubro not in ('C','I','F'))
		    
               if @w_saldo > 0
               begin
                 if @w_tipo_saldo = 'N'
				 begin
                    --print '[sp_crea_reestructura] Operacion a reestructurar ' + @w_banco + ' tiene un saldo pendiente intereses y otros rubros: ' + convert(varchar(30),@w_saldo)
					select @w_return = 725166 -- La Operacion a reestructurar tiene un saldo pendiente de intereses y otros rubros
					goto ERROR
				 end
                 if @w_tipo_saldo = 'S'
				 begin
                    --print '[sp_crea_reestructura] Operacion a reestructurar ' + @w_banco + ' tiene un saldo de otros rubros: ' + convert(varchar(30),@w_saldo)
					select @w_return = 725167 -- La Operacion a reestructurar tiene un saldo pendiente de otros rubros
					goto ERROR
				 end
               end
            end
		    
            if @w_tipo_saldo in ('T','X')
            begin
		    
               select @w_saldo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
               from ca_amortizacion
               where am_operacion = @w_operacionca
		    
               if @w_saldo <= 0
               begin
                 --print '[sp_crea_reestructura] Operacion a reestructurar ' + @w_banco + ' tiene saldo en cero: ' + convert(varchar(30),@w_saldo)
                 select @w_return = 725155 -- La Operacion a reestructurar tiene saldo en cero
				 goto ERROR
               end
            end
            --Desplegar todos los errores de todas las operaciones
            if @w_return = 0
            begin
               if @i_banco = @w_banco
               begin
                  select @w_operacion_base = 'S'
		    
                  --Ccuando en la operacion final no se reestructuran saldos, el saldo de capital por vencer se suma al valor a reestructurar
                  if @w_tipo_saldo = 'X'
                  begin
		    
                     select @w_saldo = isnull(sum(am_cuota - am_pagado),0)
                     from   ca_amortizacion, ca_rubro_op, ca_dividendo
                     where  am_operacion  = @w_operacionca
                     and    ro_operacion  = am_operacion
                     and    am_operacion  = di_operacion
                     and    ro_operacion  = di_operacion
                     and    di_dividendo  = am_dividendo
                     and    ro_concepto   = am_concepto
                     and    di_estado     = @w_est_novigente
                     and    ro_tipo_rubro = 'C'
		    
                     if @i_saldo_reest > 0 select @i_saldo_reest = @i_saldo_reest + @w_saldo
		    
                     select @w_saldo = 0
                  end
				  
				  if @w_tipo_saldo in ('N','S')
                  BEGIN
				  
				     select @w_saldo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
                     from ca_rubro_op, ca_amortizacion
                     where ro_operacion = @w_operacionca
                     and   am_estado    <> @w_est_cancelado
                     and   ro_operacion = am_operacion
                     and   ro_concepto  = am_concepto
                     and   (@w_tipo_saldo <> 'N' or ro_tipo_rubro = 'C')
                     and   (@w_tipo_saldo <> 'S' or ro_tipo_rubro in ('C','I','F'))
                  
                  end
               end
               else
                  select @w_operacion_base = 'N'
		    
               if @i_saldo_reest = 0  --La reestructura no implica movimientos de saldos
                  select @w_saldo = 0
		    
               insert into ca_op_renovar_tmp
               select @s_user, @s_term, @w_operacionca, @w_saldo, @w_operacion_base
		    
               if @@error <> 0
               begin
                  select @w_return = 710001
                  --select @w_msg_error = 'Error al insertar en ca_op_renovar_tmp'
                  goto ERROR       
               end
		    
            end --@w_return = 0
		 end -- fin REESTRUCTURACION E
		 else -- DIFERIMIENTO D
		 begin
		 
		    if @i_banco = @w_banco
               select @w_operacion_base = 'S'
		
			-- Si es diferimiento, se obtiene el saldo de capital de los dividendos No vigentes
			select @w_saldo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
            from   ca_amortizacion, ca_rubro_op, ca_dividendo
            where  am_operacion  = @w_operacionca
            and    ro_operacion  = am_operacion
            and    am_operacion  = di_operacion
            and    ro_operacion  = di_operacion
            and    di_dividendo  = am_dividendo
            and    ro_concepto   = am_concepto
            and    di_estado     = @w_est_novigente
            and    ro_tipo_rubro = 'C'
			
			select @i_saldo_reest = 0
			select @w_saldo = 0
			
			insert into ca_op_renovar_tmp
               select @s_user, @s_term, @w_operacionca, @w_saldo, @w_operacion_base
		    
               if @@error <> 0
               begin
                  select @w_return = 710001
                  --select @w_msg_error = 'Error al insertar en ca_op_renovar_tmp'
                  goto ERROR       
               end
			   
		 end
         
      end --fin while
   end --fin @w_largo_trama

   if @w_return <> 0
   begin
     -- select @w_msg_error = '[sp_crea_reestructura] Revisar los errores reportados'
     select @w_return = 711079 -- 'La fecha valor de la(s) operacion(es) a cancelar no coincide con las fecha de la reestructura'
     goto ERROR
   end

   --Pasar a temporales

   if @i_debug = 'S' print 'Pasar a tablas temporales'

   exec @w_return = sp_crear_tmp
   @s_user            = @s_user,
   @s_term            = @s_term, 
   @i_banco           = @i_banco,
   @i_accion          = 'R',
   @i_bloquear_salida = 'S',    
   @i_saldo_reest     = @i_saldo_reest    

   if @w_return <> 0
   begin
      --select @w_msg_error = 'Error al momento de sp_crear_tmp'
      goto ERROR       
   end
   
   select @w_operacionca = op_operacion,
          @w_tdividendo  = op_tdividendo
   from ca_operacion
   where op_banco = @i_banco

   select @w_div_vigente = di_dividendo
   from ca_dividendo
   where di_operacion = @w_operacionca
   and di_estado      = @w_est_vigente

   select @w_div_vigente = isnull(@w_div_vigente,0)

   if @w_div_vigente = 0
   begin
      select @w_return = 701179 --No existe Dividendo VIGENTE 
      goto ERROR       
   end
   
   --En el vencimiento del dividendo vigente se reestructura desde el siguiente
   /*if exists (select 1
        from   ca_dividendo
        where  di_operacion = @w_operacionca
        and    di_dividendo = @w_div_vigente
        and    (di_fecha_ven = @w_fecha_ult_proceso or di_fecha_ini = @w_fecha_ult_proceso) )

      select @w_div_vigente = @w_div_vigente + 1*/

   select @w_max_div = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca

   select @w_plazo_restante = @w_max_div - @w_div_vigente

   --Actualizacion de operacion final a reestructurar

   if @i_saldo_reest <= 0 select @i_saldo_reest = null  --para que tome el mismo saldo actual de la operacion
   
   -- KDR crear op_temporal con fecha ini del primer no vigente.
   SELECT @w_fecha_ini_nueva = di_fecha_ini 
   FROM ca_dividendo 
   WHERE di_dividendo = @w_div_vigente+1
   and di_operacion = @w_operacionca

   if @i_debug = 'S' print 'Modificar operacion'

   exec @w_return = sp_modificar_operacion_int
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @s_term              = @s_term,
   @i_monto             = @i_saldo_reest,
   @i_calcular_tabla    = 'S', 
   @i_tabla_nueva       = 'S', 
   @i_salida            = 'N',
   @i_operacionca       = @w_operacionca,
   @i_banco             = @i_banco,
   @i_cuota             = 0,
   @i_tplazo            = @w_tdividendo,  -- Tipo de plazo tomado de tipo de dividendo.
   @i_plazo             = @w_plazo_restante,
   @i_tipo_reest        = @i_tipo_reest,
   @i_fecha_ini         = @w_fecha_ini_nueva
   
   if @w_return <> 0
   begin
      --select @w_msg_error = 'Error al momento de crear operación base para diferimiento o reestructuración'
      goto ERROR       
   end

   if @i_debug = 'S' print 'Fin modificar operacion'

   commit tran

end



--Aplica la reestructura desde Cartera, cancela las operaciones asociadas y actualiza la operacion final

if @i_operacion = 'R'
begin

   if not exists (select 1 from ca_op_renovar_tmp where ot_user = @s_user and ot_term = @s_term)
   begin
      select @w_return = 2103001
      --select @w_msg_error = '[sp_crea_reestructura] No existen operaciones a reestructurar'
      goto ERROR       
   end

   select 
   @w_operacionca = opt_operacion,
   @w_moneda      = opt_moneda,
   @w_deudor      = opt_cliente,
   @w_oficial     = opt_oficial,
   @w_sector      = opt_sector,
   @w_ciudad      = opt_ciudad,
   @w_toperacion  = opt_toperacion,
   @w_saldo_reest = opt_monto,
   @w_tplazo        = opt_tplazo,
   @w_destino       = opt_destino,
   @w_ente          = opt_cliente,
   @w_clase         = opt_clase,
   @w_tramite_opfinal = opt_tramite,
   @w_op_lin_credito  = opt_lin_credito,
   @w_naturaleza      = opt_naturaleza,
   @w_reajustable     = opt_reajustable
   from ca_operacion_tmp
   where opt_banco = @i_banco  --Operacion final en temporales modificada desde el FrontEnd

   create table #transaccion (
   or_id              smallint identity,
   or_num_operacion   cuenta,
   or_base            char(1),
   or_moneda_original tinyint,
   or_saldo_original  money, 
   or_rubro           catalogo null)

   select @w_monto_base = 0, @w_saldo_reest_tmp = 0, @w_saldo_op_final = 0

   -- insertar un registro en cr_op_renovar
   select op_banco, op_toperacion, op_moneda, ot_base, op_tramite, saldo = ot_saldo
   into #oper_reestructura
   from ca_operacion, ca_op_renovar_tmp
   where ot_user      = @s_user
   and   ot_term      = @s_term
   and   ot_operacion = op_operacion

   select @w_saldo_reest_tmp = isnull(Sum(saldo),0)
   from #oper_reestructura

   if @w_saldo_reest_tmp <= 0 --La reestructura no involucró saldos de ninguna operacion
      select @w_saldo_reest = 0
   else
   begin
      select @w_saldo_reest_tmp = @w_saldo_reest  --respaldo del valor total a reestructurar
      --Si se restructura saldos, pero la operacion final o base puede no hacerlo
      select @w_saldo_op_final = isnull(saldo ,0)
      from #oper_reestructura
      where ot_base = 'S'
   end

   --Respaldamos los rubros distintos de capital que se moveran de la operacion base siempre y cuando se marco saldos a reestructurar
   insert into #transaccion
   select @i_banco, 'S', @w_moneda, saldo = sum(am_acumulado + am_gracia - am_pagado), am_concepto
   from   ca_dividendo, ca_amortizacion, ca_rubro_op
   where  ro_operacion   = @w_operacionca
   and    ro_operacion   = di_operacion
   and    di_operacion   = am_operacion
   and    di_dividendo   = am_dividendo
   and    ro_concepto    = am_concepto
   and    di_estado     in (@w_est_vencido, @w_est_vigente)
   and    ro_tipo_rubro <> 'C'
   and    am_acumulado + am_gracia - am_pagado > 0  --los rubros que no tienen saldo no suben
   and    @w_saldo_op_final > 0
   group by am_concepto

   --Respaldamos el saldo de capital que se moveran de la operacion base
   insert into #transaccion
   select @i_banco, 'S', @w_moneda, saldo = sum(am_acumulado + am_gracia - am_pagado), am_concepto
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion   = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro = 'C'
   and    @w_saldo_op_final > 0
   group by am_concepto

   exec @w_return = sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_n out,
   @o_dec_nacional = @w_num_dec_mn out
 
   if @w_return <> 0 goto ERROR       

 
   begin tran

   --Crear un tramite de reestructura

   exec @s_ssn = sp_gen_sec
   @i_operacion = -1

   if isnull(@s_ssn,0) = 0  
   begin
       select @w_return = 2103001
       select @w_msg_error = 'Error al obtener secuenciales de cartera'
       goto ERROR         
   end

   if @i_debug = 'S' print 'Crear tramite de reestructura automatico'

   exec @w_return = cob_credito..sp_tramite_cca 
      @s_ssn                = @s_ssn, 
      @s_user               = @s_user,
      @s_sesn               = @s_ssn, 
      @s_term               = @s_term,
      @s_date               = @s_date, 
      @s_srv                = @s_srv,
      @s_lsrv               = @s_lsrv,
      @s_ofi                = @s_ofi,
      @t_trn                = 21020,
      @i_oficina_tr         = @s_ofi,
      @i_usuario_tr         = @s_user,
      @i_fecha_crea         = @s_date, 
      @i_oficial            = @w_oficial,
      @i_sector             = @w_sector,
      @i_ciudad             = @w_ciudad,  
      @i_fecha_apr          = @s_date, 
      @i_usuario_apr        = @s_user,      
      @i_toperacion         = @w_toperacion,
      @i_producto           = 'CCA',
      @i_monto              = @w_saldo_reest, 
      @i_tipo               = 'E',
      @i_moneda             = @w_moneda, 
      @i_periodo            = @w_tplazo,
      @i_num_periodos       = 0,
      @i_destino            = @w_destino,
      @i_ciudad_destino     = @w_ciudad,
      @i_cliente            = @w_ente, 
      @i_clase              = @w_clase,
      @i_monto_mn           = @w_saldo_reest, 
      @i_monto_des          = @w_saldo_reest,
      @o_tramite            = @w_tramite out   
      
   if @w_return <> 0
   begin
       --select @w_msg_error = 'Error al momento de crear tramite de reestructura'
       goto ERROR         
   end

   --tabla de operaciones a reestructurar

   if @i_debug = 'S' print 'Insetar operaciones a reestructurar'

   insert into cob_credito..cr_op_renovar
       (or_tramite,        or_num_operacion,   or_producto,        or_abono,
        or_moneda_abono,   or_monto_original,  or_moneda_original,
        or_saldo_original, or_fecha_ingreso,   or_oficina_tramite,
        or_base,           or_login,           or_finalizo_renovacion,
        or_cancelado,      or_toperacion)
   select
        @w_tramite,     op_banco,         'CCA',       0,
        @w_moneda,      0,                op_moneda,
        saldo,          @s_date,          @s_ofi,
        ot_base,        @s_user,          'N',
        'N',            op_toperacion
   from #oper_reestructura

   if @@error != 0
   begin
      select @w_return = 2103001
      --select @w_msg_error = '[sp_crea_reestructura] Error en insercion de operacion(es) a reestructurar'
      goto ERROR       
   end

   -- Se copian las garantias de las operaciones que se van a reprogramar a la operacion final

   if @i_debug = 'S' print 'Insetar garantias de operaciones a reestructurar en op. final'

   insert into cob_credito..cr_gar_propuesta(
   gp_tramite,        gp_garantia,     gp_fecha_mod,
   gp_abierta,        gp_porcentaje,   gp_clasificacion,
   gp_deudor,         gp_est_garantia,     gp_valor_resp_garantia,
   gp_exceso,         gp_monto_exceso )
   select distinct
   @w_tramite_opfinal, gp_garantia,      gp_fecha_mod,
   gp_abierta,       gp_porcentaje,      gp_clasificacion,
   @w_deudor,        gp_est_garantia,    gp_valor_resp_garantia,
   gp_exceso,        gp_monto_exceso
   from cob_credito..cr_gar_propuesta, #oper_reestructura
   where gp_est_garantia not in ('A','C') -- No las Canceladas
   and   gp_tramite  = op_tramite
   and   gp_tramite  <> @w_tramite_opfinal  --excluir operacion final

   if @@error != 0
   begin
      set @w_return = 143051 --Error al ingresar garantia
      goto ERROR
   end

   --Pago de operaciones reestructuradas

   select @w_fpago_reest = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and pa_nemonico = 'REESFP'

   if @@rowcount = 0 
   begin
      select @w_return = 2600023 --No existe parametro general
      goto ERROR
   end
   
   select 
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_estado_original    = op_estado
   from cob_credito..cr_op_renovar, ca_operacion
   where or_num_operacion = op_banco
   and or_tramite         = @w_tramite
   and or_base            = 'S'
       
   select @w_fecha_ini_nueva = opt_fecha_ini
   from   ca_operacion_tmp
   where  opt_operacion = @w_operacionca
   
   SELECT @w_fecha_ult_proceso = @w_fecha_ini_nueva
    
   if @w_fecha_ult_proceso <> @w_fecha_ini_nueva
   begin        
       select @w_return = 711079 -- 'La fecha valor de la(s) operacion(es) a cancelar no coincide con las fecha de la reestructura'
       goto ERROR
   end

   /** Cancelar operaciones a reestructurar, a la operacion final solo se cancelan valores pendientes de pago distintos al capital **/
   select  @w_re_banco = ''

   while 1=1
   begin

     select @w_monto_cursor = 0, @w_re_saldo = 0

     select top 1
     @w_re_banco       = op_banco, 
     @w_re_operacionca = op_operacion, 
     @w_re_moneda      = op_moneda,
     @w_re_fecha_ult_proceso = op_fecha_ult_proceso,
     @w_operacion_base       = or_base,
     @w_re_saldo             = or_saldo_original
     from  ca_operacion, cob_credito..cr_op_renovar
     where op_banco       = or_num_operacion
     and or_tramite       = @w_tramite
     and or_num_operacion > @w_re_banco
     and or_saldo_original > 0
     and or_base           = 'N'
     order by or_num_operacion

     if @@rowcount = 0 break

     if @w_fecha_ult_proceso <> @w_re_fecha_ult_proceso
     begin
        --select @w_msg_error = '[sp_crea_reestructura] La fecha valor de la operacion a cancelar ' + @w_re_banco + '  no coinciden con la fecha de la reestructura'
        select @w_return = 711079 -- 'La fecha valor de la(s) operacion(es) a cancelar no coincide con las fecha de la reestructura'
        goto ERROR
     end

     select @w_comentario     = 'CANCELACION POR REESTRUCTURA',
            @w_tipo_reduccion = 'C'  --'C' si se envia como N cobra en proyectado, ademas que da error 701190

     update ca_operacion
     set op_aceptar_anticipos = 'S'
     where op_operacion = @w_re_operacionca

     if @@error != 0
     begin
        select @w_return = 708152
        --select @w_msg_error = '[sp_crea_reestructura] Error al actualizar la operacion ' + @w_re_banco
        goto ERROR
     end

     select @w_cuenta_puente = rtrim(@w_fpago_reest) + convert(varchar(2),@w_re_moneda)

     if not exists(select 1 from ca_producto where cp_producto = @w_cuenta_puente)
     begin
        select @w_return = 710344 --Error no existe forma de pago
        goto ERROR
     end

     if @w_re_moneda <> @w_moneda
     begin

         exec @w_return = sp_consulta_divisas
         @s_date             = @w_fecha_ult_proceso,
         @t_trn              = 77541,
         @i_banco            = @w_re_banco,
         @i_concepto         = 'PAG',
         @i_operacion        = 'C',
         @i_cot_contable     = 'N',
         @i_moneda_origen    = @w_re_moneda,
         @i_valor            = @w_re_saldo, 
         @i_moneda_destino   = @w_moneda,
         @o_valor_convertido = @w_monto_cursor out,
         @o_cotizacion       = @w_cotizacion out

         if @w_return != 0 goto ERROR

     end
     else
        select @w_monto_cursor = @w_re_saldo

     select @w_saldo_reest = @w_saldo_reest - isnull(@w_monto_cursor,0)

     if @i_debug = 'S' print 'Antes de sp_pago_cartera'

     if @i_debug = 'S' print 'sp_pago_cartera: ' + @w_re_banco + ' Saldo: ' + convert(varchar(30),@w_re_saldo) + ' SaldoCursor: ' + convert(varchar(30),@w_monto_cursor) +
     ' ReMoneda: ' + convert(varchar(2),@w_re_moneda) + ' Moneda: ' + convert(varchar(2),@w_moneda) + ' @w_cotizacion ' + Convert(varchar,@w_cotizacion)

     exec @w_return = sp_pago_cartera
      @s_user                = @s_user,
      @s_term                = @s_term,
      @s_date                = @s_date,
      @s_sesn                = @s_sesn,
      @s_ssn                 = @s_ssn,
      @s_srv                 = @s_srv,
      @s_ofi                 = @s_ofi,
      @i_banco               = @w_re_banco,
      @i_beneficiario        = @w_comentario,
      @i_fecha_vig           = @w_fecha_ult_proceso,
      @i_ejecutar            = 'S',
      @i_cuenta              = 'REESTRUCTURA', 
      @i_retencion           = 0,
      @i_en_linea            = 'S',
      @i_producto            = @w_cuenta_puente,
      @i_monto_mpg           = @w_re_saldo,
      @i_moneda              = @w_re_moneda,
      @i_tipo_reduccion      = @w_tipo_reduccion, 
      @i_tipo_cobro          = 'A', -- Por definicion siempre es acumulado
      @o_secuencial_ing      = @w_secuencial_ing out

     if @w_return <> 0 goto ERROR
    
     if @i_debug = 'S' print 'Despues de pago de operacion a reestructurar'

     select @w_re_saldo = 0

     select @w_re_saldo = sum(am_acumulado + am_gracia - am_pagado)
     from ca_amortizacion
     where am_operacion = @w_re_operacionca

     --Valida si toda la operacion fue cancelada
     if (@w_re_saldo != 0)
     begin
        --select @w_msg_error = convert(varchar(30), @w_re_saldo)
        select @w_return = 725156 -- La Operacion a diferir o reestructurar tiene un saldo pendiente
        --@w_msg_error = '[sp_crea_reestructura] La operacion a reestructurar, ' + @w_re_banco + ', tiene un saldo pendiente ' + @w_msg_error
        goto ERROR
     end

     update cob_credito..cr_op_renovar
     set or_cancelado = 'S'
     where or_num_operacion = @w_re_banco
     and or_tramite = @w_tramite

     if @@error <> 0
     begin
        select @w_return = 2103001
        goto ERROR
     end
   end -- While cursor reestructura

   --Si la reest involucró saldos
   if @w_saldo_reest > 0
   begin

      if @w_saldo_op_final > 0
         select @w_monto_base = sum(am_acumulado + am_gracia - am_pagado)
         from   ca_amortizacion
         where  am_operacion   = @w_operacionca
         and    am_estado      <> @w_est_cancelado
      else
         select @w_monto_base = sum(am_acumulado + am_gracia - am_pagado)
         from   ca_rubro_op, ca_dividendo, ca_amortizacion
         where  ro_operacion   = @w_operacionca
         and    ro_operacion   = di_operacion
         and    di_operacion   = am_operacion
         and    di_dividendo   = am_dividendo
         and    ro_operacion   = am_operacion
         and    ro_concepto    = am_concepto
         and    di_estado      = @w_est_novigente
         and    ro_tipo_rubro  =  'C'

      select @w_saldo_reest = @w_saldo_reest - @w_monto_base -- Resto el monto base ya que dicha operacion no se va a Pagar

      if @i_debug = 'S' print '@w_saldo_reest ' + Convert(varchar(30), convert(float, @w_saldo_reest)) + ' @w_monto_base ' +  Convert(varchar(30), convert(float,@w_monto_base))

      if round(@w_saldo_reest,2) <> 0
      begin
   	     select @w_return = 711078--'El valor total de la reestructura no cubre las operaciones'
	     goto ERROR
      end
   end
   /* REESTRUCTURAR LA OPERACION ORIGINAL */

   if @i_debug = 'S' print 'Antes sp_reestructuracion_int_cca'

   exec @w_return = sp_reestructuracion_int_cca
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_sesn        = @s_sesn,
   @s_date        = @s_date,
   @s_ofi         = @s_ofi,
   @i_banco       = @i_banco,
   @i_saldo_reest = @w_saldo_op_final,
   @o_secuencial  = @w_secuencial_rest out

   if @w_return <> 0 goto ERROR

   if @i_debug = 'S' print 'Despues sp_reestructuracion_int_cca'

   if @i_debug = 'S' print 'Antes sp_borrar_tmp'

   exec @w_return  = sp_borrar_tmp
   @s_user        = @s_user,
   @s_sesn        = @s_sesn,
   @s_term        = @s_term,
   @i_crea_ext    = 'N',
   @i_banco       = @i_banco

   if @w_return <> 0 goto ERROR

   if @i_debug = 'S' print 'Despues sp_borrar_tmp'

   update cob_credito..cr_tramite 
   set tr_estado      = 'A',
   tr_numero_op_banco = @i_banco
   where tr_tramite = @w_tramite

   if @@error <> 0
   begin
      select @w_return = 2103001
      goto ERROR
   end

   --Detalle de la transaccion de Reestructura, la operacion base tiene dos afectaciones, el pago a 
   --rubros cancelados diferentes de capital y saldo de capital trasladado o refinanciado

   insert into #transaccion
   select 
   or_num_operacion, 
   or_base, 
   or_moneda_original, 
   or_saldo_original,
   ''
   from   cob_credito..cr_op_renovar
   where  or_tramite = @w_tramite
   and   or_base = 'N'

   if @w_saldo_reest_tmp <= 0 --si no se movió saldo, genera un detalle con valor de cero

      insert into #transaccion
      select 
      or_num_operacion, 
      or_base, 
      or_moneda_original, 
      or_saldo_original,
      @w_rubro_cap
      from   cob_credito..cr_op_renovar
      where  or_tramite = @w_tramite
      and   or_base = 'S'

   --en el reestint pudo cambiar de estado la operacion
   select @w_estado_final = op_estado
   from ca_operacion 
   where op_operacion = @w_operacionca

   select @w_periodo = 0, @w_re_banco = '', @w_id = 0

   if @i_debug = 'S' print 'Crea detalle transaccion RES'

   while 1=1
   begin

     select top 1
     @w_id             = or_id,
     @w_re_banco       = or_num_operacion, 
     @w_operacion_base = or_base, 
     @w_re_moneda      = or_moneda_original, 
     @w_re_saldo       = or_saldo_original,
     @w_rubro          = or_rubro
     from   #transaccion
     where  or_id > @w_id
     order by or_id

     if @@rowcount = 0 break

    if @i_debug = 'S' print '@w_re_banco ' + @w_re_banco + ' @w_operacion_base ' + @w_operacion_base + ' @w_re_moneda ' + convert(varchar,@w_re_moneda) + ' @w_re_saldo ' + Convert(varchar,@w_re_saldo)

	  /* operacion base o final */
	  if @w_operacion_base = 'S'
	  begin
        select 
        @w_monto      = @w_re_saldo,
		  @w_factor     = -1.0,
		  @w_concepto   = @w_rubro, --@w_rubro_cap,
		  @w_estado     = @w_estado_original

        select @w_codval_ant = (co_codigo * 1000) + (@w_estado_original * 10) + @w_periodo
        from   ca_concepto
        where  co_concepto = @w_rubro --@w_rubro_cap
     end
	  else
	  begin
	     select 
        @w_cuenta_puente = rtrim(@w_fpago_reest) + convert(varchar(2),@w_re_moneda),
        @w_monto         = @w_re_saldo,
        @w_factor        = 1.0,
        @w_estado        = @w_est_vigente

        select @w_concepto =  @w_cuenta_puente

		  select @w_codval_ant = cp_codvalor
		  from   ca_producto
		  where  cp_producto = @w_cuenta_puente
     end

     if @w_re_moneda <> @w_moneda_n 
     begin

         exec @w_return = sp_consulta_divisas
         @s_date             = @w_fecha_ult_proceso,
         @t_trn              = 77541,
         @i_banco            = @w_re_banco,
         @i_concepto         = 'PAG',
         @i_operacion        = 'C',
         @i_cot_contable     = 'N',
         @i_moneda_origen    = @w_re_moneda,
         @i_valor            = @w_re_saldo, 
         @i_moneda_destino   = @w_moneda_n,
         @o_valor_convertido = @w_monto_mn  out, --este valor no me coincide con la cotizacion entregada
         @o_cotizacion       = @w_cotizacion out

	      if @w_return != 0 goto ERROR
     end
     else
        select @w_monto_mn   = @w_monto,
	            @w_cotizacion = 1

     if @i_debug = 'S' print '@w_re_banco '+@w_re_banco+'  @w_re_moneda ' + Convert(varchar,@w_re_moneda)+ '  @w_moneda_n '+ convert(varchar,@w_moneda_n) + 
     ' @w_re_saldo ' + convert(varchar,@w_re_saldo) + ' @w_monto_mn '+ convert(varchar,@w_monto_mn) + ' @w_cotizacion ' + convert(varchar,@w_cotizacion)


     -- DETALLE DE TRANSACCION, PRIMERA VEZ
     insert  into ca_det_trn (
     dtr_operacion,      dtr_secuencial,   dtr_dividendo,
     dtr_concepto,       dtr_estado,       dtr_periodo,
     dtr_codvalor,       dtr_monto,
     dtr_monto_mn,       dtr_moneda,       dtr_cotizacion,
     dtr_tcotizacion,    dtr_afectacion,   dtr_cuenta,
     dtr_beneficiario,   dtr_monto_cont)
     values (
     @w_operacionca,     @w_secuencial_rest,    1,
     @w_concepto,        @w_estado,        @w_periodo,
     @w_codval_ant,      @w_monto*@w_factor,
     @w_monto_mn*@w_factor, @w_re_moneda,  @w_cotizacion,
     'N',                'C',              @w_re_banco,--op. de la cual provino
     '',                  0)

  	  if @@error !=0
	  begin
		 select @w_return = 708166
		 goto ERROR
     end

	  -- DETALLE DE TRANSACCION, CONTRA-PARTIDA
     select @w_codval_fin = (co_codigo * 1000) + (@w_estado_final * 10) + @w_periodo
     from   ca_concepto
     where  co_concepto = @w_rubro_cap

	  select 
     @w_concepto = @w_rubro_cap,
     @w_factor   = 1.0,
	  @w_estado   = @w_estado_final

     insert  into ca_det_trn (
     dtr_operacion,      dtr_secuencial,   dtr_dividendo,
     dtr_concepto,       dtr_estado,       dtr_periodo,
     dtr_codvalor,       dtr_monto,
     dtr_monto_mn,       dtr_moneda,       dtr_cotizacion,
     dtr_tcotizacion,    dtr_afectacion,   dtr_cuenta,
     dtr_beneficiario,   dtr_monto_cont)
     values (
     @w_operacionca,     @w_secuencial_rest,    1,
     @w_concepto,        @w_estado,        @w_periodo,
     @w_codval_fin,      @w_monto*@w_factor,
     @w_monto_mn*@w_factor, @w_re_moneda,  @w_cotizacion,
     'N',                'D',              '',
     '',                  0)

	  if @@error !=0
	  begin
		 select @w_return = 708166
		 goto ERROR
     end

   end --Detalle de la transaccion de Reestructura

   if @i_debug = 'S' print 'Fin detalle transaccion RES'

   --Capital incrementado en la operacion base, se aumenta el utilizado de la linea

   select @w_monto_utilizado = @w_saldo_reest_tmp - @w_monto_base  

   if @w_op_lin_credito is not null and @w_monto_utilizado > 0
   begin
      if @w_naturaleza = 'P'
         select @w_opcion = 'P'  -- PASIVA
      else
         select @w_opcion = 'A'  -- ACTIVA

      if @i_debug = 'S' print 'Antes cob_credito..sp_utilizacion'

      exec @w_return = cob_credito..sp_utilizacion
           @s_ofi         = @s_ofi,
           @s_user        = @s_user,
           @s_term        = @s_term,
           @s_date        = @s_date,
           @i_linea_banco = @w_op_lin_credito,
           @i_producto    = 'CCA',
           @i_toperacion  = @w_toperacion,
           @i_tipo        = 'D',
           @i_moneda      = @w_moneda,
           @i_monto       = @w_monto_utilizado,
           @i_cliente     = @w_deudor,
           @i_tramite     = @w_tramite_opfinal,
           @i_opcion      = @w_opcion,
           @i_fecha_valor = @w_fecha_ult_proceso,
           @i_modo        = 1

      if @w_return <> 0 goto ERROR

      if @i_debug = 'S' print 'Despues cob_credito..sp_utilizacion'
   end

   --luego de recalcular el plan de reajustes se obtiene de la ca_reajuste la menor siguiente a la fecha actual
   if @w_reajustable = 'S'
   begin
      select @w_fecha_reajuste = max(re_fecha)
      from ca_reajuste
      where re_operacion = @w_operacionca
      and re_fecha      <= @w_fecha_ult_proceso

	 -- KDR 29-11-2021 (En diferimiento de préstamo solo se actualiza los reajustes si el plazo aumenta y cae en un nuevo reajuste)
      /*if @w_fecha_reajuste is null
         select @w_fecha_reajuste = max(di_fecha_ini)
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_fecha_ini <= @w_fecha_ult_proceso*/

      if @i_debug = 'S' print 'Antes sp_fecha_reajuste'

      exec @w_return = sp_fecha_reajuste
      @i_banco      = @i_banco,
      @i_tipo       = 'I',
      @i_fecha_reajuste = @w_fecha_reajuste
      
      if @w_return <> 0 goto ERROR
      if @i_debug = 'S' print 'Despues sp_fecha_reajuste'
   end


   update cob_credito..cr_op_renovar
   set or_finalizo_renovacion = 'S', 
       or_sec_prn             = @w_secuencial_rest  --transaccion RES para reversa
   where or_tramite = @w_tramite

   if @@error <> 0
   begin
      select @w_return = 2103001
      goto ERROR
   end
   
   -- Recálculo de la TIR y TEA por diferimiento de préstamo.
   EXEC @w_return  = sp_tir 
     @i_banco	= @i_banco, 
	 @o_cat		= @w_cat1 output, 
	 @o_tir		= @w_tir  output, 
	 @o_tea		= @w_tea output 

   if @w_return != 0 goto ERROR

   -- ACTUALIZAR VALOR DE LA TIR Y TEA.
   update cob_cartera..ca_operacion
   set    op_valor_cat	= @w_tir,
      	  op_tasa_cap	= @w_tea
   where  op_operacion = @w_operacionca
     
   -- GFP Se actualiza valores de reestructuración
   exec cob_credito..sp_busca_diferimiento
   @s_ssn            = @s_ssn,
   @s_date           = @s_date,
   @i_banco          = @i_banco,
   @o_reestructurar  = @w_reestructurar out
   
   if (@w_reestructurar = 'S')
   begin
      update cob_cartera..ca_operacion
      set    op_reestructuracion  = 'S',
         	 op_fecha_reest       = @s_date,
	         op_numero_reest      = isnull(op_numero_reest,0) + 1
      where  op_operacion  = @w_operacionca  
	  
	  if @i_debug = 'S' print 'Actualización de restructuración en S'
   end
   
   --Borrar datos temporales
   delete ca_op_renovar_tmp
   where ot_user = @s_user
   and   ot_term = @s_term

   commit tran
end

return 0

ERROR:

if @@trancount > 0
   rollback tran

exec cobis..sp_cerror
@t_debug  = 'N',         
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_return,
@i_msg    = @w_msg_error
            
return @w_return
go

