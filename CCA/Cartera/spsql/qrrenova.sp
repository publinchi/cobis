/*qrrenova.sp************************************************************/
/*   Archivo            :        qrrenova.sp                            */
/*   Stored procedure   :        sp_qr_renovacion                       */
/*   Base de datos      :        cob_cartera                            */
/*   Producto           :        Cartera                                */
/*   Disenado por                Fabian de la Torre                     */
/*   Fecha de escritura :        Ene. 98                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Consulta para front end de renovaciones                            */
/************************************************************************/
/*                            MODIFICACIONES                            */ 
/* Ago/14/2006    Ivan Jimenez      NREQ 537 proceso operativo de       */
/*                                  renovaciones                        */
/* JUNIO-06-2007                                                        */
/* Jul/10/2007    Elcira Pelaez     Defecto Nro 5458  BAC               */
/* 14/MAY/2009    G. Alvis          Caso 373: Revisión del calculo en   */
/*                                  renovaciones de mas de una operacion*/
/* 12/NOV/2014    E. Pelaez         NR.436 Normalizacion cartera        */
/* 23/NOV/2015    E. Pelaez         Recuperrar el valor negociado       */
/*                                  antes de renovar cuando hay seguros */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_renovacion')
   drop proc sp_qr_renovacion  
go

create proc sp_qr_renovacion
   @s_ssn            int          = null,
   @s_date           datetime     = null,
   @s_user           login        = null,
   @s_term           varchar(30)  = null,    
   @s_ofi            smallint     = null,
   @s_lsrv           varchar(30)  = null,
   @s_srv            varchar(30)  = null,
   @i_banco          cuenta       = null,
   @i_formato_fecha  int          = null,
   @i_crea_ext       char(1)      = null,     -- 353 jtc 
   @o_msg_msv        varchar(255) = null out  -- 353 jtc 

as
declare   
   @w_sp_name               varchar(32),
   @w_error                 int,
   @w_operacionca           int,
   @w_tramite_ren           int,
   @w_banco                 cuenta,
   @w_moneda                smallint,
   @w_num_dec               tinyint,
   @w_num_dec_mn            tinyint,
   @w_moneda_nac            tinyint,
   @w_monto_renovar         money,
   @w_nombre                varchar(50),
   @w_beneficiario          int,
   @w_secuencial_des        int,
   @w_op_fecha_ult_proceso  datetime,
   @w_cotizacion_hoy        float,
   @w_monto_renovar_mn      money,
   @w_operacion_ant         int,
   @w_fdesembolso           catalogo,
   @w_rowcount              int,
   @w_op_monto              money,
   @w_desembolso            smallint,         -- GAL 14MAY2009 - CASO 373
   @w_op_banco_renovar      cuenta,           -- GAL 14MAY2009 - CASO 373
   @w_total_renovar         money,            -- GAL 14MAY2009 - CASO 373
   @w_fecha_ult_proceso     datetime,         -- GAL 14MAY2009 - CASO 373
   @w_login                 login,            -- GAL 14MAY2009 - CASO 373
   @w_saldo_op              money,            -- GAL 14MAY2009 - CASO 373
   @w_tramite               int,              -- GAL 14MAY2009 - CASO 373
   @w_toperacion            catalogo,         -- GAL 14MAY2009 - CASO 373
   @w_monto                 money,            -- GAL 14MAY2009 - CASO 373
   @w_fecha_liq             datetime,         -- GAL 14MAY2009 - CASO 373
   @w_saldo_rubros          money,            -- GAL 14MAY2009 - CASO 373
   @w_concepto_ren          catalogo,         -- GAL 14MAY2009 - CASO 373
   @w_desc_estado_rub       descripcion,      -- GAL 14MAY2009 - CASO 373
   @w_desc_estado_div       descripcion,      -- GAL 14MAY2009 - CASO 373
   @w_ssn                   int,              -- GAL 14MAY2009 - CASO 373
   @w_anticipado            money,             -- GAL 14MAY2009 - CASO 373
   @w_paramRenFechaValor    char(1),
   @w_tr_tipo               catalogo,
   @w_operacion_new         int


-- INICIALIZACION DE VARIABLES Y ESTRUCTURAS AUXILIARES
select @w_sp_name       = 'sp_qr_renovacion'

---CODIGO DEL RUBRO TIMBRE
select @w_paramRenFechaValor = 'N'

select @w_paramRenFechaValor = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FRENOV'


/* INICIO GAL 15/MAY/2009 - CASO 373 */

create table #rubros_renov(
   tmp_am_concepto     catalogo      null,     
   tmp_am_es_estado    descripcion   null,
   tmp_di_es_estado    descripcion   null
)

-- CONSULTA DE DATOS GENERALES DE LA OPERACION QUE RENUEVA
select @w_tramite_ren          = op_tramite,
       @w_moneda               = op_moneda,
       @w_beneficiario         = op_cliente,
       @w_operacion_ant        = op_operacion,
       @w_nombre               = op_nombre,
       @w_op_monto             = op_monto,
       @w_op_fecha_ult_proceso = op_fecha_ult_proceso
from   ca_operacion
where  op_banco       = @i_banco
and    op_tramite is not null

if @@rowcount = 0
begin
   select @w_error = 710559
   goto ERROR
end

select @w_tr_tipo = tr_tipo 
from cob_credito..cr_tramite
where tr_tramite = @w_tramite_ren

if @w_tr_tipo = 'M'
begin
   select @w_error = 724561
   goto ERROR
end



-- EN CASO QUE EL DESEMBOLSO DE LA OPERACION QUE RENUEVA SE HAYA REVERSADO
-- VALIDA QUE SE REVERSEN TAMBIEN LOS PAGOS HECHOS EN LA RENOVACION
if exists(select 1 
          from cob_credito..cr_op_renovar
          where or_tramite             = @w_tramite_ren
          and   or_finalizo_renovacion = 'S'           )
begin
   select @w_error = 724516
   goto ERROR
end

-- VALIDA QUE EXISTAN OPERACIONES PENDIENTES DE RENOVAR PARA EL TRAMITE
select 
   or_num_operacion,       or_login
into #op_renovar
from cob_credito..cr_op_renovar
where or_tramite             = @w_tramite_ren
and   or_finalizo_renovacion = 'N'

if @@rowcount = 0
begin
   select @w_error = 724514
   goto ERROR
end

-- CONSULTA DEL VALOR ANTICIPADO
exec @w_error = sp_desembolso
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_operacion      = 'Q',
   @i_desde_cre      = 'N',
   @i_banco_ficticio = @i_banco,
   @i_banco_real     = @i_banco,
   @i_pasar_tmp      = 'S',
   @i_renovaciones   = 'S',
   @i_origen         = 'B',
   @o_anticipado     = @w_anticipado out

if @w_error <> 0
   goto ERROR
   
exec @w_error = sp_borrar_tmp 
   @i_banco = @i_banco
 
if @w_error <> 0
   goto ERROR


-- CURSOR PARA ACTUALIZACION DE SALDOS DE LAS OPERACIONES A RENOVAR
if isnull(@i_crea_ext,'N') = 'N'
   begin tran

declare cur_act_saldos_op_ren cursor for 
select 
   or_num_operacion,       or_login
from #op_renovar
for read only
      
open cur_act_saldos_op_ren
   
fetch cur_act_saldos_op_ren into
   @w_op_banco_renovar,    @w_login
      
while @@fetch_status = 0
begin 
   select 
      @w_operacionca = op_operacion,
      @w_tramite     = op_tramite,
      @w_toperacion  = op_toperacion,
      @w_monto       = op_monto,
      @w_moneda      = op_moneda,
      @w_fecha_liq   = op_fecha_liq
   from ca_operacion
   where op_banco = @w_op_banco_renovar
        
   -- CALCULO DE SALDOS DE LA OPERACION A RENOVAR
   
   exec @w_error = sp_saldo_cca
      @s_user       = @s_user,
      @i_banco      = @w_op_banco_renovar,
      @i_modo       = 1,
      @i_origen     = 'B'
   
   if @w_error <> 0
   begin
      close cur_act_saldos_op_ren
      deallocate cur_act_saldos_op_ren
   
      goto ERROR
   end
      
   select @w_saldo_op = sum(sot_saldo_mn)
   from ca_saldo_operacion_tmp
   where sot_operacion = @w_operacionca    
   
   select @w_saldo_rubros = sum(tmp_saldo)
   from ca_saldos_rubros_tmp
   where tmp_op_tramite = @w_tramite
   and   tmp_user       = @s_user
      
   -- REINGRESO DEL REGISTRO DE RENOVACION CON LOS SALDOS ACTUALIZADOS
   exec @w_ssn = ADMIN...rp_ssn
   
   exec @w_error = cob_credito..sp_op_renovar
      @s_ssn             = @w_ssn,
      @s_date            = @s_date,
      @s_user            = @w_login,
      @s_term            = @s_term,
      @s_ofi             = @s_ofi,            
      @s_lsrv            = @s_lsrv,
      @s_srv             = @s_srv,
      @t_trn             = 21030,
      @i_operacion       = 'I',
      @i_tramite         = @w_tramite_ren,
      @i_num_operacion   = @w_op_banco_renovar,
      @i_toperacion      = @w_toperacion,
      @i_monto_original  = @w_monto,
      @i_saldo_original  = @w_saldo_op,
      @i_moneda_original = @w_moneda,
      @i_fecha_concesion = @w_fecha_liq,
      @i_producto        = 'CCA',
      @i_aplicar         = 0,
      @i_saldo_renovar   = @w_saldo_rubros
   
   if @w_error <> 0
   begin
      close cur_act_saldos_op_ren
      deallocate cur_act_saldos_op_ren
   
      goto ERROR
   end
         
   -- ELIMINACION DE LOS RUBROS A RENOVAR ANTERIORES
   
   exec @w_error = cob_credito..sp_rub_renovar   
      @t_trn        = 21773,
      @i_operacion  = 'D',
      @i_banco      = @w_op_banco_renovar,
      @i_tramite_re = @w_tramite_ren      
      
   if @w_error <> 0
   begin
      close cur_act_saldos_op_ren
      deallocate cur_act_saldos_op_ren
   
      goto ERROR
   end
   
   -- INSERCION DE LOS RUBROS A RENOVAR QUE LA OPERACION 
   -- TIENE ACTUALMENTE PARA ASEGURAR SU CANCELACION
   truncate table #rubros_renov
   
   insert into #rubros_renov
   select 
      tmp_am_concepto,     tmp_am_es_estado,       tmp_di_es_estado         
   from ca_saldos_rubros_tmp tmp
   where tmp_op_tramite = @w_tramite
   and   tmp_user       = @s_user
         
   declare cur_act_rub_op_ren cursor for 
   select 
      tmp_am_concepto,     tmp_am_es_estado,       tmp_di_es_estado         
   from #rubros_renov
   for read only
   
   open cur_act_rub_op_ren
   
   fetch cur_act_rub_op_ren into
      @w_concepto_ren,     @w_desc_estado_rub,     @w_desc_estado_div
         
   while @@fetch_status = 0
   begin    
      exec @w_error = cob_credito..sp_rub_renovar
         @t_trn           = '21771',
         @i_operacion     = 'I',
         @i_banco         = @w_op_banco_renovar,
         @i_concepto      = @w_concepto_ren,
         @i_renovar       = 0,
         @i_estado        = @w_desc_estado_rub,
         @i_estado_cuota  = @w_desc_estado_div, 
         @i_tramite_re    = @w_tramite_ren
      
      if @w_error <> 0
      begin
         close cur_act_rub_op_ren
         deallocate cur_act_rub_op_ren
         
         close cur_act_saldos_op_ren
         deallocate cur_act_saldos_op_ren
         
         goto ERROR
      end
      
      fetch cur_act_rub_op_ren into
         @w_concepto_ren,     @w_desc_estado_rub,     @w_desc_estado_div
   end
   
   close cur_act_rub_op_ren
   deallocate cur_act_rub_op_ren
   
   fetch cur_act_saldos_op_ren into
      @w_op_banco_renovar,    @w_login
end   

close cur_act_saldos_op_ren
deallocate cur_act_saldos_op_ren
   
/* FIN GAL 15/MAY/2009 - CASO 373 */   
                       

-- DETERMINACION DEL SALDO TOTAL A RENOVAR

exec sp_saldo_cca
   @s_user          = @s_user,
   @i_banco         = @i_banco,
   @i_modo          = 2,
   @i_tramite_re    = @w_tramite_ren,
   @i_cca           = 'S'
   
delete  ca_desembolso
where dm_operacion = @w_operacion_ant


---CODIGO DEL RUBRO TIMBRE
select @w_fdesembolso = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FDESRE'

select @w_rowcount = @@rowcount

set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 711072
   goto ERROR
end 


-- REVISA DE QUE LAS OPERACIONES A RENOVAR SE ENCUENTREN A LA FECHA DE PROCESO
---print 'qrrenova.sp @w_paramRenFechaValor ' + cast (@w_paramRenFechaValor as varchar)
select 
@w_fecha_ult_proceso = op_fecha_ult_proceso, 
@w_total_renovar     = sum(tmpr_saldo_renovar)
from  ca_saldos_op_renovar_tmp, 
      ca_operacion
where tmpr_user       = @s_user
and   tmpr_tramite_re = @w_tramite_ren
and   op_banco        = tmpr_banco
group by op_fecha_ult_proceso

if @@rowcount > 1 or (@w_fecha_ult_proceso <> @s_date  and  @i_banco  not in ('170210153871','170800028822', '1110MP-12278-1','1110MP-15763-1','140470038590','140470039531','170030073671','140510037082' ))
begin
   if @w_paramRenFechaValor = 'N'
   begin
      select @w_error = 724512
      goto ERROR
   end
end

-- SI EL MONTO A RENOVAR ES MENOR QUE EL DE LA NUEVA OPERACION ENTONCES SI HAY REGISTRO DE DESEMBOLSO
-- CASO CONTRARIO NO  POR QUE EL USUARIO DEBE HACERLO MANUALMENTE

/* INICIO GAL 15/MAY/2009 - CASO 373 */

if  @w_total_renovar + @w_anticipado < @w_op_monto
begin

   select @w_desembolso = 1
   
   exec @w_secuencial_des = sp_gen_sec 
      @i_operacion  = @w_operacion_ant
      
   -- CREACION DE TANTOS DESEMBOLSOS COMO OPERACIONES A RENOVAR
      
   declare cur_op_renovar cursor for 
   select 
      tmpr_banco,            tmpr_saldo_renovar
   from ca_saldos_op_renovar_tmp
   where tmpr_user       = @s_user
   and   tmpr_tramite_re = @w_tramite_ren
   for read only
      
   open cur_op_renovar
   
   fetch cur_op_renovar into
      @w_op_banco_renovar,   @w_monto_renovar
   
   while @@fetch_status = 0
   begin      
   
      exec @w_error = sp_decimales
           @i_moneda       = @w_moneda,
           @o_decimales    = @w_num_dec out,
           @o_mon_nacional = @w_moneda_nac out,
           @o_dec_nacional = @w_num_dec_mn out
      
      if @w_error <> 0
         goto ERROR
      
      ---INSERTAR DETALLE DEL DESEMBOLSO
      
      -- OBTENER LA COTIZACION DE ESE DIA
      select 
         @w_cotizacion_hoy   = 1,
         @w_monto_renovar_mn = @w_monto_renovar
              
      if @w_moneda <> 0
      begin
         exec sp_buscar_cotizacion
            @i_moneda     = @w_moneda,
            @i_fecha      = @w_op_fecha_ult_proceso,
            @o_cotizacion = @w_cotizacion_hoy out
            
         if @w_cotizacion_hoy is null
            select @w_cotizacion_hoy = 1
               
         select @w_monto_renovar_mn = round(@w_monto_renovar *  @w_cotizacion_hoy, @w_num_dec_mn)      
      end

      insert into ca_desembolso
             (dm_secuencial,      dm_operacion,         dm_desembolso,
              dm_producto,        dm_cuenta,            dm_beneficiario,
              dm_oficina_chg,     dm_usuario,           dm_oficina,
              dm_terminal,        dm_dividendo,         dm_moneda,
              dm_monto_mds,       dm_monto_mop,         dm_monto_mn,
              dm_cotizacion_mds,  dm_cotizacion_mop,    dm_tcotizacion_mds,
              dm_tcotizacion_mop, dm_estado,            dm_cod_banco,
              dm_cheque,          dm_fecha,             dm_prenotificacion,
              dm_carga,           dm_concepto,          
              dm_valor,           dm_ente_benef,        dm_idlote)
      values (@w_secuencial_des,  @w_operacion_ant,     @w_desembolso,
              @w_fdesembolso,     @i_banco,             @w_nombre, 
              @s_ofi,             @s_user,              @s_ofi,
              @s_term,            1,                    0,
              @w_monto_renovar,   @w_monto_renovar,     @w_monto_renovar_mn,
              @w_cotizacion_hoy,  @w_cotizacion_hoy,    'C',
              'C',                'NA',                 0,
              '0',                @s_date,              0,
              0,                  'REGISTRO DESEMBOLSO RENOVACION',          
              0,                  @w_beneficiario,      0)
      
      if @@error <> 0
      begin
         close cur_op_renovar
         deallocate cur_op_renovar
      
         select @w_error = 711073
         goto ERROR
      end
      
      select @w_desembolso = @w_desembolso + 1
      
      fetch cur_op_renovar into
         @w_op_banco_renovar,   @w_monto_renovar
   end
   
   close cur_op_renovar
   deallocate cur_op_renovar   
end
else
begin
   select @w_error = 724513
   goto ERROR
end

if isnull(@i_crea_ext,'N') = 'N'
   commit tran

/* FIN GAL 15/MAY/2009 - CASO 373 */
---FIN INSERTAR DETALLE RENOVACION
-- ENVIAR INFORMACION AL FRONT END 

if isnull(@i_crea_ext,'N') <> 'S' begin   -- 353 jtc 

  select @w_operacion_new  = op_operacion
   from   ca_operacion 
   where  op_tramite = @w_tramite_ren

	if exists(select 1 from cob_credito..cr_seguros_tramite
			where st_tramite = @w_tramite_ren)
	begin     
		update  cob_cartera..ca_rubro_op
		set ro_valor = tr_monto_solicitado
		from cob_credito..cr_tramite,
			cob_cartera..ca_operacion
 		where ro_operacion =  @w_operacion_new
		and ro_operacion = op_operacion 
		and  ro_concepto ='CAP'
		and  op_tramite = tr_tramite
		and   tr_tramite = @w_tramite_ren
		if @@ERROR <> 0 
		begin
			PRINT 'qrrenova.sp error  actualizando el monto de ca_rubro_op'
			select @w_error = 705076
			goto ERROR
		end 

		update cob_cartera..ca_operacion set
		op_monto          = tr_monto_solicitado,
		op_monto_aprobado = tr_monto_solicitado      
		from cob_credito..cr_tramite
		where op_tramite = tr_tramite
		and   tr_tramite = @w_tramite_ren
		if @@ERROR <> 0 
		begin
			PRINT 'qrrenova.sp error  actualizando el monto de ca_operacion'
			select @w_error = 705076
			goto ERROR
		end 
	end 




   select 'Nro. Operacion'    = substring(tmpr_banco,1,16),
          'Linea '            = substring(tmpr_linea,1,10),
          'Monto Original'    = tmpr_monto_des,
          'Total Renovar'     = tmpr_saldo_renovar * 1.0,
          'Saldo Total'       = tmpr_saldo_hoy,
          'Moneda Op'         = tmpr_moneda,
          'Cotizacion'        = case when op_moneda = 0 then 1.0
                                else ( select ct_valor*1.0
                                       from   cob_conta..cb_cotizacion
                                       where  ct_moneda = o.op_moneda
                                       and    ct_fecha  = (select max(ct_fecha)
                                                           from   cob_conta..cb_cotizacion
                                                           where  ct_moneda = o.op_moneda
                                                           and    ct_fecha <= o.op_fecha_ult_proceso))
                                end
   from   ca_saldos_op_renovar_tmp,
          ca_operacion o
   where  tmpr_user       = @s_user
   and    tmpr_tramite_re = @w_tramite_ren
   and    op_banco = tmpr_banco

   select op_banco,
          op_moneda,
          (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'cl_moneda' and c.tabla = t.codigo and c.codigo = convert(varchar, o.op_moneda)),
          op_toperacion,
          (select c.valor from   cobis..cl_tabla t, cobis..cl_catalogo c where  t.tabla = 'ca_toperacion' and c.tabla = t.codigo and c.codigo = o.op_toperacion),
          op_monto
   from   ca_operacion o
   where  op_tramite = @w_tramite_ren


   --RETORNA LOS CONCEPTOS SELECCIONADOS
   select 'CONCEPTO'          = rr_concepto,
          'ESTADO CONCEPTO'   = (select  substring(es_descripcion ,1,10)
                                 from ca_estado where es_codigo = R.rr_estado),
          'OBLIG. ANTERIOR' = op_banco,
          'ESTADO CUOTA' = (select substring(es_descripcion,1,10) 
                            from ca_estado where es_codigo = R.rr_estado_cuota)
   from     cob_credito..cr_op_renovar, 
            cob_cartera..ca_operacion, 
            cob_credito..cr_rub_renovar R
   where    or_tramite     = @w_tramite_ren
   and      op_banco       = or_num_operacion
   and      rr_tramite     = op_tramite 
   and      rr_tramite_re  = or_tramite

   select   @w_tramite_ren       -- NUMERO DE TRAMITE CONSULTADO

end -- if isnull(@i_crea_ext,'N') <> 'S'

return 0

ERROR:

if isnull(@i_crea_ext,'N') <> 'S' begin 

   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error

end

return @w_error

go

