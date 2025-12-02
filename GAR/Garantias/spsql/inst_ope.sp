/*************************************************************************/
/*   Archivo:              inst_ope.sp                                   */
/*   Stored procedure:     sp_inst_ope                                   */
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
IF OBJECT_ID('dbo.sp_inst_ope') IS NOT NULL
    DROP PROCEDURE dbo.sp_inst_ope
go
create proc sp_inst_ope  (
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
   @i_filial		 tinyint = null,
   @i_tipo     		 descripcion = null,
   @i_moneda		 tinyint = null,
   @i_valor		 money = null,
   @i_operac		 char(1) = null,
   @i_signo              int = null,
   @i_codigo_externo     varchar(64) = null,
   @i_numero             int = null,
   @i_fecha              datetime = null,
   @i_descripcion        descripcion = null,
   @i_instruccion        varchar(200) = null,
   @i_registrado         char(1)     = null,
   @i_cliente            int         = null,
   @i_usuario            descripcion = null,
   @i_fecha_insp         datetime    = null,
   @i_inspector          tinyint         = null,
   @i_formato_fecha      int         = null,
   @i_param1             varchar(64) = null,
   @i_param2             varchar(64) = null,
   @i_login              varchar(64) = null,
   @i_tramite            int         = null
 
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_ayer               datetime,     /* fecha de ayer */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_valor		 money,
   @w_valor_me		 money,
   @w_cotizacion	 money,
   @w_secuencial         smallint,
   @w_moneda_local       tinyint,
   @w_cliente            int,
   @w_tramite            int,
   @w_numero             int,
   @w_linea              int,
   @w_operacion          varchar(64),
   @w_inspector          varchar(64),
   @w_est_cancelado      tinyint,
   @w_est_precancelado   tinyint,
   @w_est_anulado        tinyint,
   @w_tipo               char(1),
   @w_instruccion        varchar(200)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_inst_ope'
select @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)
/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19730 and @i_operacion = 'I') or
   (@t_trn <> 19731 and @i_operacion = 'S') or
   (@t_trn <> 19732 and @i_operacion = 'V') or
   (@t_trn <> 19733 and @i_operacion = 'E')   
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

   select @w_est_cancelado = es_codigo
   from cob_cartera..ca_estado
   where es_codigo = 3

   select @w_est_precancelado = es_codigo
   from cob_cartera..ca_estado
   where es_codigo = 5

   select @w_est_anulado = es_codigo
   from cob_cartera..ca_estado
   where es_codigo = 6

if @i_operacion = 'I'
begin
         begin tran

         if @i_usuario is null
            select @i_usuario = @s_user
       
         if @i_tipo = 'A'
            select @w_inspector = is_nombre
              from cu_inspector
             where is_inspector = @i_inspector
 
         select @w_cliente = cg_ente
           from cu_cliente_garantia
          where cg_codigo_externo = @i_codigo_externo
            and cg_principal = 'S'

         if exists(select 1 from cob_credito..cr_gar_propuesta,
                   cob_credito..cr_tramite,cob_cartera..ca_operacion
                   where gp_garantia = @i_codigo_externo
                     and gp_tramite = tr_tramite
                     and tr_numero_op_banco is not null
                     and op_banco = tr_numero_op_banco
                     and op_estado <> @w_est_cancelado
                     and op_estado <> @w_est_precancelado
                     and op_estado <> @w_est_anulado) 
            select @w_existe = 1
         else
            select @w_existe = 0

         if @w_existe = 0
         begin
             select @w_tipo = tr_tipo
             from cob_credito..cr_tramite,cob_credito..cr_gar_propuesta
             where gp_garantia = @i_codigo_externo
               and tr_tramite  = gp_tramite

            if @w_tipo = 'L'
               select @w_tramite = @i_tramite
            if @w_tipo = 'O' or @w_tipo = 'R'
               select @w_tramite = 0

            if @i_tipo = 'G' 
               select @i_instruccion = 'Crear una operacion por: '+ 
                      convert(varchar(20),@i_valor)
                      +' por motivo de Gastos Administrativos ' +
                      'del cliente: '+convert(varchar(10),@w_cliente)
            if @i_tipo = 'A'
               select @i_instruccion = 'Crear una operacion por: '+ 
                      convert(varchar(20),@i_valor)
                      +' por motivo de Pago a Avaluadores '+
                      'a favor de: '+@w_inspector+' y el deudor es: '+
                      convert(varchar(10),@w_cliente)
         end
         else
         begin   
            select @w_tramite     = gp_tramite,
                   @w_operacion   = tr_numero_op_banco
              from cob_credito..cr_gar_propuesta,cob_credito..cr_tramite
             where gp_garantia = @i_codigo_externo
               and gp_tramite  = tr_tramite

            if @i_tipo = 'G' 
               select @i_instruccion = 'Cobrar: '+ convert(varchar(20),@i_valor)
                      +' en un rubro'+
                      ' por motivo de Gastos Administrativos al tramite '+
                      convert(varchar(10),@w_tramite) 
            if @i_tipo = 'A'
               select @i_instruccion = 'Cobrar: '+ convert(varchar(20),@i_valor)
                      +' en un rubro'+
                      ' por motivo de Pago a Avaluadores al tramite '+
                      convert(varchar(10),@w_tramite) 
         end 

         select @w_moneda_local = pa_tinyint     -- MONEDA LOCAL
           from cobis..cl_parametro
          where pa_producto = 'ADM'
            and pa_nemonico = 'MLO'

       -- TRANSACCIONES SOLO EN MONEDA LOCAL
        /*select @w_cotizacion = isnull(ct_compra,1) 
         from cob_inst_ope..cb_cotizacion
         where ct_moneda = @i_moneda
           and ct_fecha  in (select max(ct_fecha)
                               from cob_conta..cb_cotizacion
                              where ct_fecha <= @w_today
                                and ct_moneda = @i_moneda)

         select @w_cotizacion = isnull(@w_cotizacion,0)


         if exists (select * from cob_conta..cb_empresa
         where em_empresa = @i_filial
           and em_moneda_base = @i_moneda)

            select @w_valor    = @i_valor,
                   @w_valor_me = 0
         else  -- Moneda extranjera
            select @w_valor    = @i_valor * @w_cotizacion,
		   @w_valor_me = @i_valor   */

         select @w_secuencial = isnull(max(io_numero),0) + 1
           from cu_inst_operativa
          where io_codigo_externo = @i_codigo_externo
       
 
	 insert into cu_inst_operativa (
                io_codigo_externo,
                io_numero,
                io_fecha,
                io_tipo,
                io_tramite,
                io_operacion,
                io_instruccion,
                io_valor,
                io_moneda,
                io_registrado,
                io_cliente,
                io_usuario)
	values (
                @i_codigo_externo,
                @w_secuencial,
		@s_date,
		@i_tipo,
                @w_tramite,
		@w_operacion,
	  	@i_instruccion,
		@i_valor,
		@w_moneda_local,
		'N',
                @w_cliente,
		@i_usuario)

           if @@error <> 0
           begin
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = @w_error
              return 1 
           end

           update cu_gastos
           set    ga_registrado = 'S'
           where  ga_codigo_externo = @i_codigo_externo
             and  @i_tipo           = 'G'
           
           update cu_inspeccion
           set    in_registrado = 'S'
           where  in_codigo_externo = @i_codigo_externo
             and  in_fecha_insp     = @i_fecha_insp 
             and  @i_tipo           = 'A'

           commit tran
           return 0
end

if @i_operacion = 'S'
begin
   set rowcount 10 
   select "GARANTIA"=substring(io_codigo_externo,1,20),
          "NUM"=io_numero,
          "LOGIN"=io_usuario,
          "TRAMITE"=io_tramite,
          "OPERACION"=io_operacion,
          "FECHA"=convert(char(10),io_fecha,@i_formato_fecha),
          "INSTRUCCION"=io_instruccion   
     from cu_inst_operativa
    where io_registrado = 'N'
      and ((io_codigo_externo > @i_codigo_externo or (
           io_codigo_externo = @i_codigo_externo and io_numero > @i_numero))
           or @i_codigo_externo is null)
     order by io_codigo_externo, io_numero --CSA Migracion Sybase
    if @@rowcount = 0
    begin
       if @i_codigo_externo is null
       begin
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1901004 
          return 1
       end
       else
          return 1	
    end      
end

if @i_operacion = 'V'
begin
   select @w_tipo = tr_tipo
     from cob_credito..cr_tramite
    where tr_tramite = @i_tramite
      and tr_tramite is not null

   create table #cu_temporal
   (producto varchar(10),
    tipo     varchar(20),
    banco    varchar(20))

   if @i_tramite <> 0 and @w_tipo = 'L'
   begin
      select @w_linea = li_numero
        from cob_credito..cr_linea
       where li_tramite = @i_tramite

      insert #cu_temporal
      select tr_producto,
             tr_toperacion,
             tr_numero_op_banco
        from cob_credito..cr_tramite,cob_cartera..ca_operacion
       where tr_linea_credito = @w_linea
         and op_banco         = tr_numero_op_banco
         and op_estado       <> @w_est_cancelado
         and op_estado       <> @w_est_precancelado
         and op_estado       <> @w_est_anulado
   end   
   
   if @i_tramite <> 0 and (@w_tipo = 'O' or @w_tipo = 'R')
   begin
      insert #cu_temporal
      select tr_producto,
             tr_toperacion,
             tr_numero_op_banco
        from cob_credito..cr_tramite,cob_cartera..ca_operacion
       where tr_tramite       = @i_tramite
         and op_banco         = tr_numero_op_banco
         and op_estado       <> @w_est_cancelado
         and op_estado       <> @w_est_precancelado
   end

   set rowcount 20
   select producto,tipo,banco from #cu_temporal
    where  ((tipo > @i_param1 or (tipo = @i_param1 and 
             banco > @i_param2)) or
             @i_param2 is null)
   order by tipo,banco
end

if @i_operacion = 'E'
begin
   begin tran
   select @w_numero = isnull(max(in_numero),0) + 1
     from cob_credito..cr_instrucciones
    where in_tramite = @i_tramite

   select @w_instruccion = io_instruccion
     from cu_inst_operativa
    where io_codigo_externo = @i_codigo_externo
      and io_numero         = @i_numero
 
   insert into cob_credito..cr_instrucciones
          (in_tramite,
           in_numero,
           in_codigo,
           in_login_reg,
           in_fecha_reg,
           in_texto,
           in_parametro)
   values (@i_tramite,
           @w_numero,
           'GAR',
           @i_login,
           @i_fecha,
           @w_instruccion,
           'GAR') 

   -- ACTUALIZO EL STATUS
   update cu_inst_operativa
   set    io_registrado = 'S'
   where  io_codigo_externo = @i_codigo_externo
     and  io_numero         = @i_numero

   commit tran
end
go