/************************************************************************/
/*   NOMBRE LOGICO:      7x24obsal.sp                                   */
/*   NOMBRE FISICO:      sp_7x24_obtencion_saldos                       */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       William Lopez                                  */
/*   FECHA DE ESCRITURA: 20/Dic/2022                                    */
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
/*                        PROPOSITO                                     */
/*  Genera saldos de las operaciones de cartera para fuera de linea     */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR                   RAZON                         */
/*  20/Dic/2022   William Lopez           Emision Inicial               */
/*  05/Sep/2023   Kevin Rodriguez         R214636 Optimización proceso  */
/*  13/Sep/2023   Guisela Fernandez       R215286 Ing. de proceso de fe-*/
/*                                        cah valor                     */
/*  03/Oct/2023   Mateo Cordova			  Nuevo parametro para ejecutar */
/*										  o no el fecha valor			*/
/*  06/Nov/2023   Kevin Rodriguez         R218803 Correccion saldo OP   */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_7x24_obtencion_saldos' and type = 'P')
    drop procedure sp_7x24_obtencion_saldos
go

create procedure sp_7x24_obtencion_saldos
(
   @s_ssn           		int           = null,
   @s_sesn          		int           = null,
   @s_ofi           		smallint      = null,
   @s_rol           		smallint      = null,
   @s_user          		login         = null,
   @s_date          		datetime      = null,
   @s_term          		descripcion   = null,
   @t_debug         		char(1)       = 'N',
   @t_file          		varchar(10)   = null,
   @t_from          		varchar(32)   = null,
   @s_srv           		varchar(30)   = null,
   @s_lsrv          		varchar(30)   = null,
   @t_trn           		int           = null,
   @s_format_date   		int           = null,
   @s_ssn_branch    		int           = null,
   @i_sarta         		int          = null,
   @i_batch         		int          = null,
   @i_secuencial    		int          = null,
   @i_corrida       		int          = null,
   @i_intento       		int          = null,
   @i_reproceso     		char(1)      = 'N',
   @s_culture       		varchar(10)  = 'NEUTRAL',
   @i_param1        		char(1)      = 'N', --REPROCESO(S/N)
   @i_param2 				char(1) 	 = 'S'
)
as 
declare
   @w_sp_name             varchar(65),
   @w_return              int,
   @w_retorno_ej          int,
   @w_error               int,   
   @w_mensaje             varchar(1000),
   @w_mensaje_err         varchar(1000),
   @w_contador            int,
   @w_err_cursor          char(1),
   @w_cod_prod_cca        int,
   @w_fecha_proc          datetime,
   @w_est_vigente         smallint,
   @w_est_novigente       smallint,
   @w_est_credito         smallint,
   @w_est_cancelado       smallint,
   @w_est_anulado         smallint,
   @w_so_id               int,
   @w_so_operacion        int,
   @w_so_op_banco         varchar(30),
   @w_so_op_ref_gpal      varchar(30),
   @w_so_op_gpal          char(1),
   @w_so_saldo_pago       money,
   @w_so_fecha_proc       datetime,
   @w_amounttopay         money,
   @w_reference           varchar(30),
   @w_sarta               int,
   @w_batch               int,
   @w_so_tipo_cobro       char(1),
   @w_so_fecha_ult_proc   datetime,
   @w_saldo_acum          money,
   @w_saldo_proy          money

select @w_sp_name       = 'sp_7x24_obtencion_saldos',
       @w_error         = 0,
       @w_return        = 0,
       @w_retorno_ej    = 0,
       @w_mensaje       = '',
       @w_contador      = 0,
       @w_err_cursor    = 'N',
       @i_reproceso     = @i_param1

-- CULTURA
exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from   cobis..ba_log,
       cobis..ba_batch
where  ba_arch_fuente like '%sp_7x24_obtencion_saldos%'
and    lo_batch   = ba_batch
and    lo_estatus = 'E'

-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
   
-- Fecha de Proceso
select @w_fecha_proc = fc_fecha_cierre 
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_cca

if exists(select 1
          from   ca_7x24_saldos_prestamos
          where  sp_fecha_proceso = @w_fecha_proc
          and    @i_reproceso     = 'N')
begin

   select @w_error  = 725246, --Ya se generaron saldos para el fuera de línea de CARTERA, para obtenerlos nuevamente se debe ejecutar el proceso en modo reproceso
          @w_return = @w_error

   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = @w_error   

   return @w_return

end

if @i_reproceso = 'S'
begin
   delete  ca_7x24_saldos_prestamos
   where   sp_fecha_proceso = @w_fecha_proc
   
   delete  ca_7x24_fcontrol
   where   fc_fecha_proceso = @w_fecha_proc
end

--Estados de Cartera
exec @w_return = sp_estados_cca 
   @o_est_vigente   = @w_est_vigente   out, --1
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out  --6

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   
   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = @w_return   
   
   return @w_return   
end

--creacion de tabla de trabajo para el universo de operaciones
if exists (select 1 from sysobjects where name = '#saldos_ope')
   drop table #saldos_ope

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al borrar tabla #saldos_ope',
          @w_return  = @w_error
   goto ERROR
end

--Tabla temporal para poder agregar a los saldos una columna con la cuenta contable respectiva
create table #saldos_ope(
   so_id              int         identity(1,1),
   so_operacion       int         not null,
   so_op_banco        varchar(30) not null,
   so_op_ref_gpal     varchar(30) null,
   so_op_gpal         char(1)     null,
   so_saldo_pago      money       null,
   so_fecha_proc      datetime    not null,
   so_tipo_cobro      char(1)     not null,
   so_fecha_ult_proc  datetime    not null
)
select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear tabla #saldos_ope',
          @w_return  = @w_error
   goto ERROR
end

--Insercion de universo de las operaciones individuales
insert into #saldos_ope(
       so_operacion,   so_op_banco,     so_op_ref_gpal,
       so_op_gpal,     so_saldo_pago,   so_fecha_proc,
	   so_tipo_cobro,  so_fecha_ult_proc
       )
select op_operacion,   op_banco,        op_ref_grupal,
       op_grupal,      null,            @w_fecha_proc,
	   op_tipo_cobro,  op_fecha_ult_proceso
from   ca_operacion
where  op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito, @w_est_anulado)

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar tabla #saldos_ope',
          @w_return  = @w_error
   goto ERROR
end

create nonclustered index idx_saldos_ope_1
    on #saldos_ope(so_op_ref_gpal)
    
create nonclustered index idx_saldos_ope_2
    on #saldos_ope(so_op_banco)    

-- Saldos de Operaciones Individuales y Grupales Hijas
declare cur_saldos_operaciones cursor
for select
    so_id,            so_operacion,      so_op_banco,      so_op_ref_gpal,
    so_op_gpal,       so_fecha_proc,     so_tipo_cobro,    so_fecha_ult_proc
    from   #saldos_ope

    open cur_saldos_operaciones    
    fetch next from cur_saldos_operaciones into
    @w_so_id,         @w_so_operacion,   @w_so_op_banco,   @w_so_op_ref_gpal,
    @w_so_op_gpal,    @w_so_fecha_proc,  @w_so_tipo_cobro, @w_so_fecha_ult_proc

    while (@@fetch_status = 0)
    begin
       if (@@fetch_status = -1)
       begin
          select @w_error = 710004

          close cur_saldos_operaciones    
          deallocate cur_saldos_operaciones

          exec cobis..sp_cerror 
              @t_debug = 'N', 
              @t_file  = '', 
              @t_from  = @w_sp_name, 
              @i_num   = @w_error

          return @w_error
       end
       
       select @w_amounttopay = null,
              @w_reference   = null,
		      @w_mensaje     = '',
		      @w_saldo_proy  = 0,
		      @w_saldo_acum  = 0
		   
       if @w_so_fecha_ult_proc < @w_fecha_proc
       begin
	      if @i_param2 = 'S' --MCO condicional para ejecutar el fecha valor
	      begin
			  exec @w_return = sp_fecha_valor
	            @s_ssn               = @s_ssn, 
	            @s_date              = @s_date,
	            @s_user              = @s_user,
	            @s_term              = @s_term,
	            @i_fecha_valor       = @w_fecha_proc,
	            @i_banco             = @w_so_op_banco,
	            @i_operacion         = 'F',
	            @i_en_linea          = 'N'
				
				if @w_return <> 0
				begin
	               select @w_mensaje = mensaje, 
	                      @w_err_cursor = 'S'
	               from cobis.dbo.cl_errores
	               where numero = @w_return
	               goto ERROR
				end
		   end
		   else
		   begin
		   		select @w_mensaje    = 'La fecha valor de la operación es menor a la fecha proceso,no se puede generar saldo de la operación: ' + @w_so_op_banco,
	                   @w_return     = 725299, -- La fecha valor de la operación es menor a la fecha proceso. Por favor, acercarse a la institución para su revisión	,
	                   @w_err_cursor = 'S'
	            goto ERROR
		   end
		   
       end

		   
       /* --ejecucion de sp para obtener el monto del pago
       exec @w_return = cob_cartera..sp_interfaz_pago_enl
       @s_ssn               = @s_ssn,
       @s_sesn              = @s_sesn,
       @s_ofi               = @s_ofi,
       @s_rol               = @s_rol,
       @s_user              = @s_user,
       @s_date              = @s_date,
       @s_term              = @s_term,
       @t_debug             = @t_debug,     
       @t_file              = @t_file,
       @t_from              = @t_from,
       @s_srv               = @s_srv,
       @s_lsrv              = @s_lsrv,
       @t_trn               = @t_trn,
       @s_format_date       = @s_format_date,   
       @s_ssn_branch        = @s_ssn_branch,
       @i_canal             = '2', --canal batch
       @i_aplica_en_linea   = 'N', --batch
       @i_operacion         = 'Q', --Q: Consulta saldo pago, P: Procesar pago
       @i_idcolector        = 0,                --Codigo de Banco o colector en Bancos
       @i_numcuentacolector = '',               --Numero de Cuenta en Bancos
       @i_idreferencia      = 0,                --Numero de referencia (Boleta)
       @i_reference         = @w_so_op_banco,   --Numero de operacion de Cartera - op_banco
       @i_amounttopay       = 0.00,             --Monto a pagar
       @i_fuera_linea       = 'N',
       @i_fecha_pago        = @w_so_fecha_proc,       
       @o_amounttopay       = @w_amounttopay       out,
       @o_reference         = @w_reference         out
	    
       select @w_error = @w_return
       if @w_return != 0 or @@error != 0
       begin
          select @w_mensaje    = 'Se produjo un error en la ejecucion de cob_cartera..sp_interfaz_pago_enl',
                 @w_return     = @w_error,
                 @w_err_cursor = 'S'
    
          goto ERROR
       end*/
	   
	   -- Monto pago del préstamo (Saldo exigible de cuotas completas donde el vencimientos de estas cuotas es menor o igual a fecha proceso)
	   select @w_saldo_proy =isnull(sum((abs(am_cuota + am_gracia - am_pagado)+am_cuota + am_gracia - am_pagado)/2.0),0),
              @w_saldo_acum = isnull(sum((abs(am_acumulado + am_gracia - am_pagado)+am_acumulado + am_gracia - am_pagado)/2.0),0)
       from  ca_dividendo,
             ca_amortizacion,
             ca_rubro_op,
             ca_concepto
       where di_operacion = @w_so_operacion
       and   di_operacion = am_operacion
       and   di_operacion = ro_operacion
       and   am_concepto  = ro_concepto
       and   (di_estado  = 2 or di_estado = 1 )
	   and   di_fecha_ven <= @w_fecha_proc
       and   co_concepto  = am_concepto
       and   am_estado    <> 3
       and  (
             (am_dividendo = di_dividendo + charindex (ro_fpago, 'A') and not(co_categoria in ('S','A') and am_secuencia > 1)
             )
             or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = di_dividendo)
            )
	
       if @w_so_tipo_cobro = 'P'
	      select @w_amounttopay = @w_saldo_proy
	   
       if @w_so_tipo_cobro = 'A'
	      select @w_amounttopay = @w_saldo_acum

       if (@w_amounttopay is not null)
       begin
          update #saldos_ope
          set    so_saldo_pago = @w_amounttopay
          where  so_op_banco   = @w_so_op_banco
          
          select @w_error = @@error
          if @@rowcount != 1 or @w_error != 0
          begin
             select @w_mensaje    = 'Se produjo un error en la actualizacion de #saldos_ope',
                    @w_return     = @w_error,
                    @w_err_cursor = 'S'
          
             goto ERROR
          end       
       end

       NEXT_LINE_CURSOR:
          fetch next from cur_saldos_operaciones into
          @w_so_id,         @w_so_operacion,   @w_so_op_banco,   @w_so_op_ref_gpal,
          @w_so_op_gpal,    @w_so_fecha_proc,  @w_so_tipo_cobro, @w_so_fecha_ult_proc

    end--fin de while

close cur_saldos_operaciones    
deallocate cur_saldos_operaciones

--Insercion de universo de las operaciones grupales
insert into #saldos_ope(
       so_operacion,   so_op_banco,     so_op_ref_gpal,
       so_op_gpal,     so_saldo_pago,   so_fecha_proc,
	   so_tipo_cobro,  so_fecha_ult_proc
       )
select distinct
       op_operacion,   op_banco,        op_ref_grupal,
       op_grupal    ,  null,            @w_fecha_proc,
	   op_tipo_cobro,  op_fecha_ult_proceso
from   ca_operacion with (nolock),
       #saldos_ope
where  op_banco       = so_op_ref_gpal
and    so_op_gpal     = 'S'
and    so_op_ref_gpal is not null
and    op_grupal      = 'S'
and    op_ref_grupal is null

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar tabla #saldos_ope',
          @w_return  = @w_error
   goto ERROR
end

-- Saldos de Operaciones Grupales Padre.
update #saldos_ope
set so_saldo_pago = s.saldo_total
from (select so_op_ref_gpal, 
             sum(so_saldo_pago) as saldo_total 
      from #saldos_ope t 
	  where so_op_ref_gpal is not null
      group by so_op_ref_gpal) s, 
      #saldos_ope m
where s.so_op_ref_gpal = m.so_op_banco  
and  m.so_op_gpal      = 'S'
and  m.so_op_ref_gpal is null

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al actualizar tabla #saldos_ope',
          @w_return  = @w_error
   goto ERROR
end

-- Nullear saldo OPs Padre si al menos una hija no tiene un saldo individual.
update #saldos_ope
set so_saldo_pago = null
from (select so_op_ref_gpal
      from #saldos_ope t
      where so_op_ref_gpal is not null
      and so_saldo_pago is null
      group by so_op_ref_gpal) s, 
      #saldos_ope m
where s.so_op_ref_gpal = m.so_op_banco  
and  m.so_op_gpal      = 'S'
and  m.so_op_ref_gpal is null

--Llenar tablas definitivas
if exists(select 1 
          from   #saldos_ope
          where  so_saldo_pago is not null)
begin
   insert into ca_7x24_saldos_prestamos(
          sp_fecha_proceso,   sp_num_banco,   sp_num_operacion,   sp_saldo_a_pagar
          )
   select so_fecha_proc,      so_op_banco,    so_operacion,       so_saldo_pago
   from   #saldos_ope
   where  so_saldo_pago is not null
   
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al insertar tabla ca_7x24_saldos_prestamos',
             @w_return  = @w_error
      goto ERROR
   end
   
   insert into ca_7x24_fcontrol(fc_fecha_proceso)          
   values (@w_fecha_proc)
   
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al insertar tabla ca_7x24_fcontrol',
             @w_return  = @w_error
      goto ERROR
   end          
   
end

return 0

ERROR:

   if @w_err_cursor = 'S'
   begin
      select @w_mensaje_err = isnull(@w_mensaje, re_valor)
      from   cobis..cl_errores inner join cobis..ad_error_i18n 
          on (numero = pc_codigo_int and re_cultura like '%'+@s_culture+'%')
      where  numero = @w_return
	  
	  if @w_mensaje_err is not null 
         select @w_mensaje =  null

	  exec sp_errorlog
           @i_fecha       = @w_fecha_proc, 
           @i_error       = @w_return, 
           @i_usuario     = 'opebatch',
           @i_tran        = 7000, 
           @i_tran_name   = @w_sp_name, 
           @i_rollback    = 'N',
           @i_cuenta      = @w_so_op_banco, 
           @i_descripcion = @w_mensaje	
	  
   end 

   exec @w_retorno_ej = cobis..sp_ba_error_log
        @i_sarta      = @w_sarta,
        @i_batch      = @w_batch,
        @i_secuencial = @i_secuencial,
        @i_corrida    = @i_corrida,
        @i_intento    = @i_intento,
        @i_error      = @w_return,
        @i_detalle    = @w_mensaje  

   if @w_err_cursor = 'S'
   begin
      select @w_err_cursor = 'N'

      goto NEXT_LINE_CURSOR
   end 		
      
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_return
   end
go
