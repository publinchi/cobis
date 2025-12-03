/**********************************************************************/
/*  Archivo:            op_renovar.sp                                 */
/*  Stored procedure:       sp_op_renovar                             */
/*  Base de Datos:          cob_credito                               */
/*  Producto:           Credito                                       */
/*  Disenado por:           Myriam Davila                             */
/*  Fecha de Documentacion:     14/Ago/95                             */
/**********************************************************************/
/*                     IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios que son         */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,    */
/*   representantes exclusivos para comercializar los productos y     */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida   */
/*   y regida por las Leyes de la República de España y las           */
/*   correspondientes de la Unión Europea. Su copia, reproducción,    */
/*   alteración en cualquier sentido, ingeniería reversa,             */
/*   almacenamiento o cualquier uso no autorizado por cualquiera      */
/*   de los usuarios o personas que hayan accedido al presente        */
/*   sitio, queda expresamente prohibido; sin el debido               */
/*   consentimiento por escrito, de parte de los representantes de    */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto    */
/*   en el presente texto, causará violaciones relacionadas con la    */
/*   propiedad intelectual y la confidencialidad de la información    */
/*   tratada; y por lo tanto, derivará en acciones legales civiles    */
/*   y penales en contra del infractor según corresponda.             */
/**********************************************************************/
/*          PROPOSITO                                                 */
/*  Este stored procedure permite realizar operaciones DML            */
/*  Search y Query en la tabla cr_op_renovar                          */
/*                                                                    */
/**********************************************************************/
/*          MODIFICACIONES                                            */
/*  FECHA       AUTOR           RAZON                                 */
/*  14/Ago/95   Ivonne Ordonez      Emision Inicial                   */
/*  26/Feb/98   Myriam Davila       Nueva opcion de buscar            */
/*  07/Abr/06   Viviana Arias       Agrega campos.                    */
/*  27/Jun/22   Bruno Duenas        Se agrega campos a actualizar     */
/*  13/Jun/23   Dilan Morales     Se añade validacion al borrar op-S840145*/
/*  27/Jun/23   Dilan Morales       Se modifica operaciones D, I y U  */
/*                                  para controlar operaciones hijas  */
/*  02/Oct/23   Dilan Morales       R216450: Se valida operacion padre*/
/**********************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_op_renovar')
    drop proc sp_op_renovar
go

create proc sp_op_renovar (
   @s_ssn                int      = null,
   @s_user               login    = null,
   @s_sesn               int    = null,
   @s_term               descripcion = null,
   @s_date               datetime = null,
   @s_srv        varchar(30) = null,
   @s_lsrv       varchar(30) = null,
   @s_rol        smallint = null,
   @s_ofi                smallint  = null,
   @s_org_err        char(1) = null,
   @s_error      int = null,
   @s_sev        tinyint = null,
   @s_msg        descripcion = null,
   @s_org        char(1) = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo       tinyint = null,
   @i_tramite            int  = null,
   @i_num_operacion      cuenta  = null,
   @i_producto           catalogo  = null,
   @i_abono              money  = null,
   @i_moneda_abono       tinyint  = null,
   @i_monto_original     money = null,
   @i_saldo_original     money = null,
   @i_fecha_concesion    datetime = null,
   @i_toperacion     catalogo = null,
   @i_moneda_original    tinyint = null,
   @i_aplicar           char(1)  = 'S',  --RBU
   @i_capitaliza        char(1)  = 'N',   --RBU
   @i_saldo_renovar     money    = 0,
   /* campos cca 353 alianzas bancamia --AAMG*/
   @i_crea_ext          char(1)       = null,
   @i_tipo_tramite      char(1)      = null,     -- Req. 436 Normalizacion
   @i_cliente           int          = null,     -- Req. 436 Normalizacion
   @i_numero_op_banco   cuenta       = null,     -- Req. 436 Normalizacion
   @i_grupo             catalogo     = null,     -- Req. 436 Normalizacion
   @i_cuota_prorrogar   int          = null,     -- Req. 436 Normalizacion
   @i_fecha_prorrogar   datetime     = null,     -- Req. 436 Normalizacion
   @i_op_base           CHAR(1)      = NULL,
   @o_msg_msv           varchar(255)  = null out
)
as
declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_tramite            int,
   @w_num_operacion      cuenta,
   @w_producto           catalogo,
   @w_abono              money,
   @w_moneda_abono       tinyint,
   @w_desc_moneda    descripcion,
   @w_monto_original     money,
   @w_saldo_original     money,
   @w_fecha_concesion    datetime,
   @w_toperacion     catalogo,
   @w_moneda_original    tinyint,
   @w_desc_moneda_orig   descripcion,
   @w_monto_inicial  money,
   @w_moneda_inicial     money,
   @w_tramite_ant    int,
   @w_def_moneda     tinyint,
   @w_aplicar            char(1),  --RBU
   @w_capitaliza         char(1),  --RBU   
   @w_nm_tramite         int,      --Req 436 Normalizacion
   @w_nm_cliente         int,      --Req 436 Normalizacion
   @w_nm_operacion       cuenta,   --Req 436 Normalizacion
   @w_nm_tipo_norm       catalogo, --Req 436 Normalizacion
   @w_nm_cuota           int,      --Req 436 Normalizacion
   @w_nm_fecha           datetime,  --Req 436 Normalizacion
   @w_base               char(1),
   @w_tipo_tra           char(1),
   @w_tramite_hijo       int,
   @w_op_anterior_hija   cuenta,
   @w_operacionca_padre  int 

select @w_today = @s_date
select @w_sp_name = 'sp_op_renovar'

--- Verificar si la operacion ya fue asignada a otra renovacion 
if @i_operacion = 'C'
begin
   if exists (select 1
              from   cr_op_renovar, 
                     cr_tramite,
                     cob_cartera..ca_operacion
              where  or_num_operacion = @i_num_operacion
              and    or_tramite       = tr_tramite
              and    tr_tramite       = op_tramite
              and    tr_tipo          in ('R','E')
              and    tr_estado        not in ('Z','X','R','S')
              and    op_estado         in (99,0))
         
begin
      if @i_crea_ext is null
      begin
         --- Ya existe un tramite con esa operacion 
    exec cobis..sp_cerror
    @t_from  = @w_sp_name,
              @i_num   = 2101097
         return 1 
      end
      else
      begin
         select @o_msg_msv = 'Operacion: ' + @i_num_operacion + ' Asociada a otra renovacion, ' + @w_sp_name
         select @w_return  = 2101097
         return @w_return
      end
   end
end

if @i_operacion = 'K'
begin
   BEGIN TRAN
   
   delete cr_rub_renovar
   from   cr_op_renovar
   where  or_login = @s_user
   and    or_tramite < 0
   and    rr_tramite_re = or_tramite
   
   if @@error <> 0
   begin
      ROLLBACK
      
      if @i_crea_ext is null
      begin
         print 'Error limpiando area de trabajo (det)'
    return 1 
end
      else
      begin
         select @o_msg_msv = 'Error limpiando area de trabajo cr_rub_renovar 1, ' + @w_sp_name
         select @w_return  = 607100
         return @w_return
      end
   end
   
   delete cr_op_renovar
   where  or_login = @s_user
   and    or_tramite < 0
   
   if @@error <> 0
   begin
      ROLLBACK
      
      if @i_crea_ext is null
      begin
         print 'Error limpiando area de trabajo (det)'
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Error limpiando area de trabajo cr_op_renovar 2, ' + @w_sp_name
         select @w_return  = 607100
         return @w_return
      end
   end
   
   --Req 436 Normalizacion
   if @i_tipo_tramite = 'M'
   begin
      delete cob_credito..cr_normalizacion
      where nm_tramite < 0
      and   nm_login = @s_user
      
      if @@error <> 0
      begin
         ROLLBACK
      
         if @i_crea_ext is null
         begin
            print 'Error limpiando area de trabajo (det)'
            return 1
         end
         else
         begin
            select @o_msg_msv = 'Error limpiando area de trabajo cr_normalizacion, ' + @w_sp_name
            select @w_return  = 607100
            return @w_return
         end
      end
   end
   
   COMMIT
end

if @i_operacion = 'U' -- ACTUALIZAR TRAMITE REAL
begin
   BEGIN TRAN
   
   if @i_tramite is null
   begin
      if @i_crea_ext is null
      begin
         print 'cr_op_re.sp Error llego vacio el NRo. de tramite nuevo REVISARRRR'
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Error llego vacio el NRo. de tramite nuevo, ' + @w_sp_name
         select @w_return  = 710391
         return @w_return
      end
   end
   
   update cr_rub_renovar
   set    rr_tramite_re = @i_tramite
   from   cr_op_renovar
   where  or_login = @s_user
   and    or_tramite < 0
   and    rr_tramite_re = or_tramite
   
   if @@error <> 0
   begin
      ROLLBACK
      
      if @i_crea_ext is null
      begin
         print 'Error actualizando tramite real (det)'
         return 1
      end
      else
      begin
         select @o_msg_msv = 'Error actualizando tramite real, Tramite: ' + @i_tramite + ', ' + @w_sp_name
         select @w_return  = 355519
         return @w_return
      end
   END
   
   --PQU no estaba actualizando 
   update cob_credito..cr_op_renovar
   set    or_abono                = @i_abono,
          or_moneda_abono         = @i_moneda_abono,
          or_saldo_original       = @i_saldo_original,
          or_capitaliza           = @i_capitaliza,
          or_base                 = @i_op_base,
          or_toperacion           = @i_toperacion,
          or_monto_original       = @i_monto_original
    where or_tramite = @i_tramite and
          or_num_operacion = @i_num_operacion and
          or_producto = @i_producto
   
    if @@error <> 0 
    begin
		ROLLBACK
       /* Error en actualizacion de registro */
       exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2105001
             return 1 
    end
	
	if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
	begin
	
		select @w_operacionca_padre = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite
		
		declare cursor_op_hijas cursor READ_ONLY for
		select hija.or_tramite, hija.or_num_operacion from cob_credito..cr_op_renovar padre
		inner join cob_cartera..ca_operacion hija_anterior on hija_anterior.op_ref_grupal  = padre.or_num_operacion
		inner join cob_credito..cr_tramite_grupal on padre.or_tramite = tg_tramite and hija_anterior.op_cliente  = tg_cliente
		inner join cob_cartera..ca_operacion hija_actual on hija_actual.op_operacion = tg_operacion
		inner join cob_credito..cr_op_renovar hija on hija.or_tramite = hija_actual.op_tramite and hija.or_num_operacion = hija_anterior.op_banco
		where padre.or_tramite  = @i_tramite  
		and padre.or_num_operacion = @i_num_operacion
		and tg_participa_ciclo  = 'S'
		and tg_operacion != @w_operacionca_padre
		and hija_anterior.op_estado not in (0, 3,9,66)
		
		open cursor_op_hijas
		fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		while @@FETCH_STATUS = 0
		begin
			update cob_credito..cr_op_renovar
			set or_capitaliza           = @i_capitaliza
			where  or_tramite       = @w_tramite_hijo
			and    or_num_operacion = @w_op_anterior_hija
			
			if @@error <> 0 
			begin
				ROLLBACK
				close cursor_op_hijas
				deallocate cursor_op_hijas
				
				/*Error en eliminacion de registro */
				exec cobis..sp_cerror
				@t_debug = @t_debug,
				@t_file  = @t_file, 
				@t_from  = @w_sp_name,
				@i_num   = 2105001
				return 1 
	
			end
			fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		end
	
		close cursor_op_hijas
		deallocate cursor_op_hijas
	end
		
   
   /* Transaccion de Servicio */
         /***************************/
   insert into ts_op_renovar
   values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cr_op_renovar',@s_lsrv,@s_srv,
           @w_tramite,
           @w_num_operacion,
           @w_producto,
           @w_abono,
           @w_moneda_abono,
           @w_monto_original,
           @w_saldo_original,
           @w_fecha_concesion,
           @w_toperacion,
           @w_moneda_original,
           @w_aplicar,
           @w_capitaliza)
   if @@error <> 0 
   begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
   end
            
   /* Transaccion de Servicio */
   /***************************/
   insert into ts_op_renovar
   values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cr_op_renovar',@s_lsrv,@s_srv,
         @i_tramite,
         @i_num_operacion,
         @i_producto,
         @i_abono,
         @i_moneda_abono,
         @w_monto_original,
         @i_saldo_original,
         @w_fecha_concesion,
         @w_toperacion,
         @w_moneda_original,
         @i_aplicar,
         @i_capitaliza)
         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
         end
    update cob_cartera..ca_operacion
    set op_anterior = @i_num_operacion
    where op_tramite = @i_tramite
   
   --fin PQU 
   
   --Req 436 Normalizacion
   if @i_tipo_tramite = 'M'
   begin
      update cob_credito..cr_normalizacion
      set nm_tramite = @i_tramite,
          nm_cuota   = @i_cuota_prorrogar,
          nm_fecha   = @i_fecha_prorrogar      
      where nm_tramite < 0
      and   nm_login = @s_user
      
      if @@error <> 0
      begin
         ROLLBACK
      
         if @i_crea_ext is null
         begin
            print 'Error actualizando tramite de normalizacion real (det)'
            return 1
         end
         else
         begin
            select @o_msg_msv = 'Error actualizando tramite de normalizacion real, Tramite: ' + @i_tramite + ', ' + @w_sp_name
            select @w_return  = 355519
            return @w_return
         end
      end
   end
   
   COMMIT
   
   return 0
end

if @i_tramite is null
begin
   select @i_tramite = -op_tramite
   from   cob_cartera..ca_operacion
   where  op_banco = @i_num_operacion
end

-- CHEQUEO DE EXISTENCIAS
if @i_operacion <> 'S' 
begin
   select    @w_tramite = or_tramite,
         @w_num_operacion = or_num_operacion,
         @w_producto = or_producto,
     @w_monto_original = or_monto_original,
     @w_saldo_original = or_saldo_original,
     @w_fecha_concesion = or_fecha_concesion,
     @w_moneda_original = or_moneda_original,
     @w_desc_moneda_orig = b.mo_descripcion,
     @w_toperacion = or_toperacion,
          @w_aplicar    = or_aplicar,     --RBU
          @w_capitaliza = or_capitaliza   --RBU
   from   cob_credito..cr_op_renovar
                    left outer join cobis..cl_moneda b on
                           or_moneda_original = b.mo_moneda                         
                     where or_tramite = @i_tramite
                       and or_num_operacion = @i_num_operacion
                       and or_producto      = @i_producto
   
    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

--- VALIDACION DE CAMPOS NULOS 

if @i_operacion = 'I' or @i_operacion = 'U'
begin
   if @i_tramite is NULL 
   or @i_num_operacion is NULL
   or @i_producto is NULL 
   begin
      if @i_crea_ext is null
    begin
         --- Campos NOT NULL con valores nulos 
         PRINT '@i_tramite %1! @i_num_operacion %2! @i_producto %3!' + cast (@i_tramite as varchar) + cast (@i_num_operacion as varchar )+ cast (@i_producto as varchar)
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1 
    end
      else
      begin
         select @o_msg_msv = 'Campos Not NULL con valores nulos, ' + @w_sp_name
         select @w_return  = 2101001
         return @w_return
end
   end
end

---Insercion del registro 
if @i_operacion = 'I'
begin
   
   -- Seleccion de codigo de moneda local 
   SELECT @w_def_moneda = pa_tinyint  
    FROM cobis..cl_parametro  
    WHERE pa_nemonico = 'MLOCR'   
   
   if @@rowcount = 0
   begin
      if @i_crea_ext is null
      begin
         -- REGISTRO NO EXISTE
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101005
         return 2101005
      end
      else
      begin
         select @o_msg_msv = 'REGISTRO NO EXISTE, ' + @w_sp_name
         select @w_return  = 2101005
         return @w_return
      end
   end
         
   BEGIN TRAN
   if @i_tramite is not null
   begin
      delete cr_op_renovar
      where  or_num_operacion = @i_num_operacion
      and    or_tramite       = @i_tramite
   end
         else
   begin
      delete cr_op_renovar
      where  or_num_operacion = @i_num_operacion
      and    or_login         = @s_user
   end 
   
   select @i_saldo_renovar = isnull(@i_saldo_renovar, 0)
   
   select @w_tipo_tra = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite
   if @w_tipo_tra in ('R', 'F')
   begin
      select @w_base = 'N'
   end
   else if @w_tipo_tra in ('E')
   begin
      select @w_base = 'S' 
   end
   insert into cr_op_renovar
         (or_tramite,         or_num_operacion,    or_producto,
          or_abono,           or_moneda_abono,     or_monto_original,
          or_saldo_original,  or_fecha_concesion,  or_toperacion,
          or_moneda_original, or_monto_inicial,    or_moneda_inicial,
          or_aplicar,         or_capitaliza,       or_login,
          or_fecha_ingreso,   or_finalizo_renovacion, or_base)
   values(@i_tramite,         @i_num_operacion,    @i_producto,
     @i_abono,           @i_moneda_abono,          isnull(@i_monto_original, 0.0),
          @i_saldo_original,  @i_fecha_concesion,  @i_toperacion,
          @i_moneda_original, @i_saldo_renovar,    @w_moneda_inicial,
          @i_aplicar,         @i_capitaliza,       @s_user,
          getdate(),          'N',                 isnull(@i_op_base, @w_base))
   
    if @@error <> 0 
    begin
	  ROLLBACK
      if @i_crea_ext is null
      begin
         -- ERROR EN INSERCION DE REGISTRO
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103001
         return 2103001
      end
      else
      begin
         select @o_msg_msv = 'Error: Insertando registro en cr_op_renovar, Tramite: ' + @i_tramite + ', ' + @w_sp_name
         select @w_return  = 2103001
         return @w_return
         end
   end
   
   if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
   begin
		select @w_tipo_tra = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite
		select @w_operacionca_padre = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite
	
		declare cursor_op_hijas cursor READ_ONLY for
		select hija_actual.op_tramite, hija_anterior.op_banco  from cob_cartera..ca_operacion hija_anterior 
		inner join cob_credito..cr_tramite_grupal on tg_cliente = op_cliente  and tg_grupo = op_grupo
		inner join cob_cartera..ca_operacion hija_actual on hija_actual.op_operacion =tg_operacion 
		where hija_anterior.op_ref_grupal = @i_num_operacion
		and tg_tramite = @i_tramite
		and tg_participa_ciclo = 'S'
		and tg_operacion != @w_operacionca_padre
		and hija_anterior.op_estado not in (0, 3,9,66)
	
		open cursor_op_hijas
		fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		while @@FETCH_STATUS = 0
		begin
			if not exists(select 1 from cob_credito..cr_op_renovar
						where  or_tramite       = @w_tramite_hijo)
			begin
				update cob_credito..cr_tramite 
				set tr_tipo = @w_tipo_tra
				where tr_tramite = @w_tramite_hijo
				if @@error <> 0 
				begin
					ROLLBACK
					close cursor_op_hijas
					deallocate cursor_op_hijas
					
					/* Error en actualizacion de registro */
					exec cobis..sp_cerror
					@t_debug = @t_debug,
					@t_file  = @t_file, 
					@t_from  = @w_sp_name,
					@i_num   = 2105001
					return 1 
				end
	
			end
		
			insert into cob_credito..cr_op_renovar 
			(or_tramite, 	or_num_operacion, 		or_producto, 	or_capitaliza, 			or_login, 	or_fecha_ingreso)
			select 
			@w_tramite_hijo, @w_op_anterior_hija, 	'CCA', 			@i_capitaliza, 			@s_user, 	@s_date
			
			if @@error <> 0 
			begin
				ROLLBACK
				close cursor_op_hijas
				deallocate cursor_op_hijas
				
				/*Error en eliminacion de registro */
				exec cobis..sp_cerror
				@t_debug = @t_debug,
				@t_file  = @t_file, 
				@t_from  = @w_sp_name,
				@i_num   = 2103001
				return 1 
	
			end
			fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		end
	
		close cursor_op_hijas
		deallocate cursor_op_hijas
   end
		
   
   -- TRANSACCION DE SERVICIO
   if exists (select 1 from cob_credito..cr_tran_servicio 
              where ts_secuencial     = @s_ssn 
              and ts_tipo_transaccion = @t_trn
              and ts_clase            = 'N')
   begin
      delete cob_credito..cr_tran_servicio 
      where ts_secuencial     = @s_ssn 
      and ts_tipo_transaccion = @t_trn
      and ts_clase            = 'N'
   end
   
         insert into ts_op_renovar
   values (@s_ssn,            @t_trn,              'N',
           @s_date,           @s_user,             @s_term,
           @s_ofi,            'cr_op_renovar',     @s_lsrv,
           @s_srv,            @i_tramite,          @i_num_operacion,
           @i_producto,       @i_abono,            @i_moneda_abono,
           @i_monto_original, @i_saldo_original,   @i_fecha_concesion,
           @i_toperacion,     @i_moneda_original,  @i_aplicar,       --RBU
           @i_capitaliza)    --RBU
   
         if @@error <> 0  
         begin
      if @i_crea_ext is null
      begin
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
         end
      else
      begin
         select @o_msg_msv = 'Error: Insertando transaccion de servicio, Tramite: ' + @i_tramite + ', ' + @w_sp_name
         select @w_return  = 2103003
         return @w_return
      end
   end
    
   --Req 436 Normalizacion
   if @i_tipo_tramite = 'M'
    begin
      if @i_tramite is not null
        begin
         delete cob_credito..cr_normalizacion
         where  nm_operacion = @i_num_operacion
         and    nm_tramite   = @i_tramite
        end
      else
      begin
         delete cob_credito..cr_normalizacion
         where  nm_operacion = @i_num_operacion
         and    nm_login     = @s_user
    end
    
      insert into cob_credito..cr_normalizacion (nm_tramite, nm_cliente, nm_operacion, nm_tipo_norm, nm_cuota, nm_fecha, nm_login)
      values (@i_tramite, @i_cliente, @i_numero_op_banco, @i_grupo, @i_cuota_prorrogar, @i_fecha_prorrogar, @s_user)
    
      if @@error <> 0 
      begin
      if @i_crea_ext is null
         begin
            -- ERROR EN INSERCION DE REGISTRO
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 2103003
            return 2103003
         end
         else
         begin
            select @o_msg_msv = 'ERROR AL CREAR EL REGISTRO EN LA NORMALIZACION, Tramite: ' + @i_tramite + ', ' + @w_sp_name
            select @w_return  = 2103003
            return @w_return
         end
end

      /* transaccion servicio cr_normalizacion */

      if exists (select 1 from cob_credito..cr_tran_servicio 
                 where ts_secuencial     = @s_ssn 
                 and ts_tipo_transaccion = @t_trn
                 and ts_clase            = 'N')
      begin
         delete cob_credito..cr_tran_servicio 
       where ts_secuencial     = @s_ssn 
         and ts_tipo_transaccion = @t_trn
         and ts_clase            = 'N'
      end

      insert into cob_credito..ts_normalizacion (transaccion, secuencial_tran, clase,
                                    usuario,     terminal,        fecha,
                                    tramite,     cliente,         operacion,
                                    tipo_norm,   cuota_prorroga,  fecha_proroga)
      values (@t_trn,     @s_ssn,             'N',
              @s_user,    @s_term,            GETDATE(),
              @i_tramite, @i_cliente,         @i_numero_op_banco,
              @i_grupo,   @i_cuota_prorrogar, @i_fecha_prorrogar)

      if @@error <> 0 
begin
      if @i_crea_ext is null
    begin
            -- ERROR EN INSERCION DE REGISTRO
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
                 @i_num   = 2103003
            return 2103003
    end
         else
         begin
            select @o_msg_msv = 'ERROR AL CREAR EL REGISTRO EN LA VISTA NORMALIZACION, Tramite: ' + @i_tramite + ', ' + @w_sp_name
            select @w_return  = 2103003
            return @w_return
         end
      end
   end   
   COMMIT TRAN 
end


if @i_operacion = 'D'
begin
   BEGIN TRAN
   
    if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
	begin
		declare cursor_op_hijas cursor READ_ONLY for
		select hija.or_tramite, hija.or_num_operacion from cob_credito..cr_op_renovar padre
		inner join cob_cartera..ca_operacion hija_anterior on hija_anterior.op_ref_grupal  = padre.or_num_operacion
		inner join cob_credito..cr_tramite_grupal on padre.or_tramite = tg_tramite and hija_anterior.op_cliente  = tg_cliente
		inner join cob_cartera..ca_operacion hija_actual on hija_actual.op_operacion = tg_operacion
		inner join cob_credito..cr_op_renovar hija on hija.or_tramite = hija_actual.op_tramite and hija.or_num_operacion = hija_anterior.op_banco
		where padre.or_tramite  = @i_tramite  
		and padre.or_num_operacion = @i_num_operacion
		and tg_participa_ciclo  = 'S'
		and hija_anterior.op_estado not in (0, 3,9,66)
		
		open cursor_op_hijas
		fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		while @@FETCH_STATUS = 0
		begin
			delete cob_credito..cr_op_renovar
			where  or_tramite       = @w_tramite_hijo
			and    or_num_operacion = @w_op_anterior_hija
			
			if @@error <> 0 
			begin
				ROLLBACK
				close cursor_op_hijas
				deallocate cursor_op_hijas
				
				/*Error en eliminacion de registro */
				exec cobis..sp_cerror
				@t_debug = @t_debug,
				@t_file  = @t_file, 
				@t_from  = @w_sp_name,
				@i_num   = 2107001
				return 1 
	
			end
			if not exists(select 1 from cob_credito..cr_op_renovar
						where  or_tramite       = @w_tramite_hijo)
			begin
				update cob_credito..cr_tramite 
				set tr_tipo = 'O'
				where tr_tramite = @w_tramite_hijo
				if @@error <> 0 
				begin
					ROLLBACK
					close cursor_op_hijas
					deallocate cursor_op_hijas
					/* Error en actualizacion de registro */
					exec cobis..sp_cerror
					@t_debug = @t_debug,
					@t_file  = @t_file, 
					@t_from  = @w_sp_name,
					@i_num   = 2105001
					return 1 
				end
			end
			fetch next from cursor_op_hijas into @w_tramite_hijo, @w_op_anterior_hija
		end
	
		close cursor_op_hijas
		deallocate cursor_op_hijas
	end
	
   
   delete cob_credito..cr_op_renovar
   where  or_tramite       = @i_tramite
   and    or_num_operacion = @i_num_operacion
   --and    or_login         = @s_user
   
    if @@error <> 0 
    begin
	  ROLLBACK
      if @i_crea_ext is null
      begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
              @i_num   = 2107001
             return 1 
      end
      else
      begin
         select @o_msg_msv = 'Error: Eliminando Registro en cr_op_renovar, Tramite: ' + @i_tramite + ', ' + @w_sp_name
         select @w_return  = 2107001
         return @w_return
      end
   end
   
   if @@rowcount > 0
   begin
      -- TRANSACCION DE SERVICIO
		insert into ts_op_renovar
		values(@s_ssn, @t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cr_op_renovar',@s_lsrv,@s_srv,
         @w_tramite,
         @w_num_operacion,
         @w_producto,
         @w_abono,
         @w_moneda_abono,
		 @w_monto_original,
		 @w_saldo_original,
		 @w_fecha_concesion,
		 @w_toperacion,
		 @w_moneda_original,
         @w_aplicar,          --RBU
         @w_capitaliza)       --RBU
            
         if @@error <> 0 
         begin
		    ROLLBACK
			if @i_crea_ext is null
			begin
				-- ERROR EN INSERCION DE TRANSACCION DE SERVICIO
				exec cobis..sp_cerror
				@t_debug = @t_debug,
				@t_file  = @t_file, 
				@t_from  = @w_sp_name,
				@i_num   = 2103003
				return 1 
			end
			else
			begin
				select @o_msg_msv = 'Error: Insertando transaccion de servicio cr_op_renovar, Tramite: ' + @w_tramite + ', ' + @w_sp_name
				select @w_return  = 2103003
				return @w_return
			end   
		end
    end
   
   delete cr_rub_renovar
   where  rr_tramite_re = @i_tramite
   
   --Req 436 Normalizacion
   if @i_tipo_tramite = 'M'
   begin
   
      /*GUARDA LOS DATOS DE LA OPERACION A ELIMINAR*/
      select
      @w_nm_tramite   = nm_tramite,
      @w_nm_cliente   = nm_cliente,
      @w_nm_operacion = nm_operacion,
      @w_nm_tipo_norm = nm_tipo_norm,
      @w_nm_cuota     = nm_cuota,
      @w_nm_fecha     = nm_fecha
      from cob_credito..cr_normalizacion 
      where nm_tramite   = @i_tramite
      and   nm_operacion = @i_num_operacion
   
      delete cob_credito..cr_normalizacion
      where nm_tramite   = @i_tramite
      and   nm_operacion = @i_num_operacion
      --and   nm_login   = @s_user
                                  
         if @@error <> 0
         begin
		 ROLLBACK
         if @i_crea_ext is null
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2107001
             return 1 
         end
         else
         begin
            select @o_msg_msv = 'Error: Eliminando Registro en cr_normalizacion, Tramite: ' + @i_tramite + ', ' + @w_sp_name
            select @w_return  = 2107001
            return @w_return
         end
      end
            
      /* transaccion servicio cr_normalizacion */
      
      insert into ts_normalizacion (transaccion, secuencial_tran, clase,
                                    usuario,     terminal,        fecha,
                                    tramite,     cliente,         operacion,
                                    tipo_norm,   cuota_prorroga,  fecha_proroga)
      values (@t_trn,          @s_ssn,        'B',
              @s_user,         @s_term,       GETDATE(),
              @w_nm_tramite,   @w_nm_cliente, @w_nm_operacion,
              @w_nm_tipo_norm, @w_nm_cuota,   @w_nm_fecha)

      /* Si no se puede insertar error */
         if @@error <> 0 
         begin
          /* Error en creacion de transaccion de servicio de parametros de normalizacion*/        
         print 'ERROR ELIMINANDO TRANSACCION DE SERVICIO ts_normalizacion...'
             return 1 
         end
end
   
   COMMIT TRAN
end

--- Search 


if @i_operacion = 'S'
begin
   if @i_crea_ext is null
   begin
   if @i_modo = 1
   -- para renovacion en cartera
       SELECT 
         'Operacion' = or_num_operacion,
         'Cancelar' = or_aplicar,        --RBU
         'Otros Rubros' = or_capitaliza  --RBU
        FROM cr_op_renovar
       WHERE (or_tramite = @i_tramite)
   else
      -- busqueda normal
       SELECT 
         'Tramite' = or_tramite, 
         'Operacion' = or_num_operacion,
         'Linea Credito' = or_toperacion,
         'Monto' = or_monto_original,
         'Saldo' = isnull(or_saldo_original,0) - isnull(or_abono,0),
         'Moneda' = convert(char(3),or_moneda_original)+' ('+b.mo_descripcion+')',
         'Fecha Concesion' = convert(char(10),or_fecha_concesion,103),
         'Producto' = or_producto,
         'Cancelar' = or_aplicar,        --RBU
         'Otros Rubros' = or_capitaliza  --RBU
         FROM cr_op_renovar
         left outer join cobis..cl_moneda b on 
         or_moneda_original = b.mo_moneda
         WHERE or_tramite = @i_tramite
   end
end


/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if (@w_existe = 1 and @i_crea_ext is null)
         select 
              @w_tramite,
              @w_num_operacion,
              @w_producto,
          @w_monto_original,
          @w_saldo_original,
              convert(char(10),@w_fecha_concesion,103),
          @w_toperacion,
          @w_moneda_original,
          @w_desc_moneda_orig,
              @w_aplicar,     --RBU
              @w_capitaliza   --RBU
    else
    begin
       if @i_crea_ext is null
       begin
          /* Registro No existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101005
        return 1 
    end
       else
       begin
          select @o_msg_msv = 'Error: No existe Registro, Tramite: ' + @w_tramite + ', ' + @w_sp_name
          select @w_return  = 2101005
          return @w_return
       end
        
    end
end
return 0
ERROR:

GO

