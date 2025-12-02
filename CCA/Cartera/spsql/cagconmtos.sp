/********************************************************************/
/*   NOMBRE LOGICO:      sp_pago_grupal_consulta_montos             */
/*   NOMBRE FISICO:      cagconmtos.sp                              */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       William Lopez                              */
/*   FECHA DE ESCRITURA: 03-Feb-2023                                */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Sp de consulta de montos de precancelacion, vencido y vigente  */
/*   de operaciones hijas asociadas a prestamo grupal               */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR           RAZON                       */
/*   03-Feb-2023        WLO             Emision Inicial             */
/*   13-Mar-2023        KDR             S795163 Sumatoria de valores*/
/*   11-Abr-2023        KDR             S785507 Resulset para CCA   */
/*   11-Sep-2023		MCO				R215032 Control pago grupal */
/********************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_pago_grupal_consulta_montos' and type = 'P')
   drop procedure sp_pago_grupal_consulta_montos
go

create procedure sp_pago_grupal_consulta_montos
(
   @s_ssn           int           = null,
   @s_sesn          int           = null,
   @s_ofi           smallint      = null,
   @s_rol           smallint      = null,
   @s_user          login         = null,
   @s_date          datetime      = null,
   @s_term          descripcion   = null,
   @t_debug         char(1)       = 'N',
   @t_file          varchar(10)   = null,
   @t_from          varchar(32)   = null,
   @s_srv           varchar(30)   = null,
   @s_lsrv          varchar(30)   = null,
   @t_trn           int           = null,
   @s_format_date   int           = null,
   @s_ssn_branch    int           = null,
   @s_culture       varchar(10)   = 'NEUTRAL',
   @i_canal         catalogo      = null, -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX
   @i_banco         varchar(30),  --Numero de operacion
   @i_operacion     char(1),      --S: consulta de montos de operaciones hijas,
   @i_opcion        char(1)     = null,      
   @o_monto_vencido money      	= null out,
   @o_monto_vigente money     	= null out,
   @o_total         money     	= null out,
   @o_total_liquidar money     	= null out
)
as 
declare
   @w_sp_name                varchar(65),
   @w_return                 int,
   @w_retorno_ej             int,
   @w_error                  int,
   @w_mensaje                varchar(1000),
   @w_mensaje_err            varchar(255),
   @w_contador               int,
   @w_err_cursor             char(1),
   @w_cod_prod_cca           int,
   @w_fecha_proc             datetime,
   @w_est_vigente            smallint,
   @w_est_novigente          smallint,
   @w_est_cancelado          smallint,
   @w_est_credito            smallint,
   @w_est_anulado            smallint,
   @w_est_castigado          smallint,
   @w_est_vencido            smallint,
   @w_tipo_operacion         char(1),
   @w_op_operacion           int,
   @w_op_tramite             int,
   @w_mh_operacion           int,
   @w_mh_banco               varchar(30),
   @w_mh_nombre_cliente      varchar(160),
   @w_mh_estado              tinyint,
   @w_mh_fecha_ini           datetime,
   @w_mh_tipo_cobro          char(1),
   @w_mh_tipo_reduccion      char(1),
   @w_mh_monto_cancelacion   money,
   @w_mh_monto_vencido       money,
   @w_mh_monto_vigente       money,
   @w_mh_monto_total         money,
   @w_mh_monto_por_vencer    money,
   @w_canal                  catalogo -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX

select @w_sp_name       = 'sp_pago_grupal_consulta_montos',
       @w_error         = 0,
       @w_return        = 0,
       @w_retorno_ej    = 0,
       @w_mensaje       = '',
       @w_contador      = 0,
       @w_err_cursor    = 'N',
       @w_mensaje_err   = null,
       @w_canal         = @i_canal
       
-- CULTURA
exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out

-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
   
-- Fecha de Proceso
select @w_fecha_proc = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_cca

--Estados de Cartera
exec @w_return = sp_estados_cca
   @o_est_vigente   = @w_est_vigente   out, --1
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out, --6
   @o_est_castigado = @w_est_castigado out, --4
   @o_est_vencido   = @w_est_vencido   out  --2   

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_error = @w_return
   goto ERROR  
end

--Obtener informacion de prestamo
select @w_op_operacion = op_operacion,
       @w_op_tramite   = op_tramite
from   ca_operacion
where  op_banco = @i_banco
if @@rowcount = 0
begin
   select @w_error   = 725054,  --No existe la operación
          @w_mensaje = 'No existe la operación'
   goto ERROR
end

-- Tipo de operación [G: Grupal Padre, H: Grupal Hija, N: Individual]
exec @w_return = sp_tipo_operacion
   @i_banco    = @i_banco,
   @i_en_linea = 'N',
   @o_tipo     = @w_tipo_operacion out

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_error = @w_return
   goto ERROR
end

if @w_tipo_operacion != 'G'
begin
   select @w_error   = 70203,  --ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL
          @w_mensaje = 'ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL'
   goto ERROR
end

if @i_operacion = 'S' --S: consulta de montos de operaciones hijas
or @i_operacion = 'R' -- Operación R, reutiliza la lógica de operación 'S'
begin
   --creacion de tabla de trabajo para el universo de operaciones
   if exists (select 1 from sysobjects where name = '#montos_ope_hijas')
      drop table #montos_ope_hijas

   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al borrar tabla #montos_ope_hijas',
             @w_return  = @w_error
      goto ERROR
   end

   --Tabla temporal para poder agregar a los saldos una columna con la cuenta contable respectiva
   create table #montos_ope_hijas(
      mh_operacion         int         not null,
      mh_banco             varchar(30) not null,
	  mh_cod_cliente       int         not null,
      mh_nombre_cliente    varchar(160)not null,
	  mh_fecha_utl_proc    datetime    not null,
      mh_estado            tinyint     not null,
      mh_fecha_ini         datetime    not null,
      mh_tipo_cobro        char(1)     not null,
      mh_tipo_reduccion    char(1)     not null,
      mh_monto_cancela     money       null,
      mh_monto_vencido     money       null,
      mh_monto_vigente     money       null,
      mh_monto_total       money       null,
	  mh_monto_por_vencer  money       null
   )
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al crear tabla #montos_ope_hijas',
             @w_return  = @w_error
      goto ERROR
   end

   --Insercion de universo de las operaciones hijas
   insert into #montos_ope_hijas(
          mh_operacion, mh_banco,      mh_cod_cliente,    mh_nombre_cliente, mh_fecha_utl_proc, 
		  mh_estado,    mh_fecha_ini,  mh_tipo_cobro,     mh_tipo_reduccion
          )
   select op_operacion, op_banco,      op_cliente,        op_nombre,         op_fecha_ult_proceso,        
          op_estado,    op_fecha_ini,  op_tipo_cobro,     op_tipo_reduccion
   from   ca_operacion,
          cob_credito..cr_tramite_grupal
   where  tg_tramite         = @w_op_tramite
   and    tg_operacion       = op_operacion
   and    tg_participa_ciclo = 'S'
   and    op_grupal          = 'S'
   and    op_estado     not in (@w_est_novigente, @w_est_cancelado, @w_est_credito, @w_est_anulado)

   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al insertar tabla #montos_ope_hijas',
             @w_return  = @w_error
      goto ERROR
   end

   create nonclustered index idx_montos_ope_hijas_1
       on #montos_ope_hijas(mh_operacion)

   declare cur_montos_ope_hijas cursor
   for select
       mh_operacion,    mh_banco,         mh_nombre_cliente,    mh_estado,
       mh_fecha_ini,    mh_tipo_cobro,    mh_tipo_reduccion
       from   #montos_ope_hijas

       open cur_montos_ope_hijas
       fetch next from cur_montos_ope_hijas into
       @w_mh_operacion, @w_mh_banco,      @w_mh_nombre_cliente, @w_mh_estado,
       @w_mh_fecha_ini, @w_mh_tipo_cobro, @w_mh_tipo_reduccion

       while (@@fetch_status = 0)
       begin
          if (@@fetch_status = -1)
          begin
             select @w_error = 710004

             close cur_montos_ope_hijas
             deallocate cur_montos_ope_hijas

             exec cobis..sp_cerror
                 @t_debug = 'N',
                 @t_file  = '',
                 @t_from  = @w_sp_name,
                 @i_num   = @w_error

             return @w_error
          end

       select @w_error                = 0,
              @w_return               = 0,
              @w_mh_monto_cancelacion = 0,
              @w_mh_monto_vencido     = 0,
              @w_mh_monto_vigente     = 0,
              @w_mh_monto_total       = 0

       --monto cancelacion
       exec @w_return = sp_calcula_saldo
          @i_operacion      = @w_mh_operacion,
          @i_tipo_pago      = @w_mh_tipo_cobro,
          @i_en_linea       = 'S',
          @i_tipo_reduccion = @w_mh_tipo_reduccion,
          @i_debug          = 'N',
          @o_saldo          = @w_mh_monto_cancelacion out

       select @w_error = @w_return
       if @w_return != 0 or @@error != 0
       begin
          select @w_error      = @w_return,
                 @w_err_cursor = 'S'

          goto ERROR  
       end

       --Monto vencido
       if  @w_mh_tipo_cobro = 'P'
       begin

          select @w_mh_monto_vencido = isnull(sum(am_cuota + am_gracia - am_pagado),0)
          from   ca_amortizacion, ca_dividendo
          where  am_operacion = di_operacion
          and    am_dividendo = di_dividendo
          and    am_operacion = @w_mh_operacion
          and    di_estado    = @w_est_vencido

          select @w_mh_monto_vigente = isnull(sum(am_cuota + am_gracia - am_pagado),0)
          from   ca_amortizacion, ca_dividendo
          where  am_operacion = di_operacion
          and    am_dividendo = di_dividendo
          and    am_operacion = @w_mh_operacion
          and    di_estado    = @w_est_vigente

       end

       if  @w_mh_tipo_cobro = 'A'
       begin

          select @w_mh_monto_vencido = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
          from   ca_amortizacion, ca_dividendo
          where  am_operacion = di_operacion
          and    am_dividendo = di_dividendo
          and    am_operacion = @w_mh_operacion
          and    di_estado    = @w_est_vencido

          select @w_mh_monto_vigente = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
          from   ca_amortizacion, ca_dividendo
          where  am_operacion = di_operacion
          and    am_dividendo = di_dividendo
          and    am_operacion = @w_mh_operacion
          and    di_estado    = @w_est_vigente

       end
	   
       select @w_mh_monto_por_vencer = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
       from   ca_amortizacion, ca_dividendo, ca_rubro_op
       where  am_operacion  = di_operacion
       and    am_dividendo  = di_dividendo
       and    am_operacion  = @w_mh_operacion
       and    di_estado     = @w_est_novigente
       and    ro_operacion  = am_operacion
	   and    ro_concepto   = am_concepto
	   and    ro_tipo_rubro = 'C'

       --Modificacion de montos de operaciones hijas
       if @w_error = 0
       begin
          update #montos_ope_hijas
          set    mh_monto_cancela    = @w_mh_monto_cancelacion,
                 mh_monto_vencido    = @w_mh_monto_vencido,
                 mh_monto_vigente    = @w_mh_monto_vigente,
                 mh_monto_total      = @w_mh_monto_vencido + @w_mh_monto_vigente,
				 mh_monto_por_vencer = @w_mh_monto_por_vencer
          where  mh_operacion = @w_mh_operacion

          select @w_error = @@error
          if @w_error != 0
          begin
             select @w_mensaje    = 'Error al modificar montos tabla #montos_ope_hijas',
                    @w_return     = @w_error,
                    @w_err_cursor = 'S'

             goto ERROR
          end

       end

       NEXT_LINE_CURSOR:
          fetch next from cur_montos_ope_hijas into
          @w_mh_operacion, @w_mh_banco,      @w_mh_nombre_cliente, @w_mh_estado,
          @w_mh_fecha_ini, @w_mh_tipo_cobro, @w_mh_tipo_reduccion
       end--fin de while

   close cur_montos_ope_hijas
   deallocate cur_montos_ope_hijas
   
   --Consulta de operaciones y montos
   if @w_error = 0 and @i_operacion = 'S' 
   begin
      if @w_canal =  4 -- ATX
	  begin
         select mh_banco,
                mh_nombre_cliente,
                mh_monto_cancela,
                mh_monto_vencido,
                mh_monto_vigente
         from   #montos_ope_hijas
         
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al consultar montos tabla #montos_ope_hijas',
                   @w_return  = @w_error
         
            goto ERROR
         end
	  end
	  
      if @w_canal =  1 -- Cartera
	  begin
         select mh_banco,
                mh_cod_cliente,
                mh_nombre_cliente,
				substring(convert(varchar,mh_fecha_utl_proc, 103),1,15),    
				es_descripcion,
                mh_monto_vencido,
                mh_monto_vigente,
				mh_monto_total,      -- vencido + vigente
				mh_monto_por_vencer,
                mh_monto_cancela,
				mh_monto_total
         from   #montos_ope_hijas, ca_estado
		 where mh_estado = es_codigo
         
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al consultar montos tabla #montos_ope_hijas',
                   @w_return  = @w_error
         
            goto ERROR
         end
	  end

   end
end

-- Está operación utiliza(depende) de la lógica de la operación 'S'
if @i_operacion = 'R' -- Consulta de sumaatorias de montos de operaciones hijas
begin
    
	/*if not exists (select 1 from #montos_ope_hijas)
    begin
       select @w_error = 725279 -- Error al obtener sumatoria total de operaciones hijas
       goto ERROR  
    end
	else*/
	   select @o_total_liquidar = isnull(sum(mh_monto_cancela),0),
              @o_monto_vencido  = isnull(sum(mh_monto_vencido),0),
              @o_monto_vigente  = isnull(sum(mh_monto_vigente),0),
			  @o_total          = isnull(sum(mh_monto_total),0)
       from   #montos_ope_hijas
  	
	

end

return @w_return

ERROR:
   if @w_err_cursor = 'S'
   begin
      close cur_montos_ope_hijas    
      deallocate cur_montos_ope_hijas   
   end

   select @w_mensaje_err = re_valor
   from   cobis..cl_errores inner join cobis..ad_error_i18n 
                            on (numero = pc_codigo_int
                            and re_cultura like '%'+@s_culture+'%')
   where  numero = @w_error

   select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
   
   if @w_canal is null or @w_canal in (1)
   begin
      exec cobis..sp_cerror
         @t_debug = 'N',
         @t_file  = null,
         @t_from  = @w_sp_name,
         @i_num   = @w_error   
   end

   return @w_error
go
