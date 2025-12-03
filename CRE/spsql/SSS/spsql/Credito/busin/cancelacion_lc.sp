 /************************************************************************/
/*  Archivo: cancelacion_lc.sp                                           */
/*  Stored procedure: sp_cancelacion_lc                                  */
/*  Base de datos: cob_credito                                           */
/*  Producto: COBIS HSBC                                                 */
/*  Disenado por: Arbey Rodriguez Martinez                               */
/*  Fecha de escritura: 23-07-2012                                       */
/*************************************************************************/
/*                         IMPORTANTE                                    */
/*  Este programa es parte de los paquetes bancarios                     */
/*  propiedad de "CobisCorp", representantes exclusivos para             */
/*  el Ecuador de "NCR".                                                 */
/*  Su uso no autorizado queda expresamente prohibido asi como           */
/*  cualquier alteracion o agregado hecho por alguno de sus              */
/*  usuarios sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de CobisCorp o su representante.               */
/*                           PROPOSITO                                   */
/*  SP para el proceso de cancelación automática de líneas de crédito    */
/*************************************************************************/
/*                           MODIFICACIONES                              */
/*  FECHA          AUTOR               RAZON                             */
/*  21-Dic-2021    Verónica Pineda     Cancelación líneas de crédito     */
/*  13-May-2022    PJA                 Modificacion Proceso Cancelacion  */
/*  19-Ago-2022    PJA                 Modificacion Estado a Vigente     */
/*************************************************************************/
use cob_credito
go

if exists(select * from sysobjects where name = 'sp_cancelacion_lc')
    drop proc sp_cancelacion_lc
go

create proc sp_cancelacion_lc(
   @s_ssn             int           = null,
   @s_date            datetime      = null,
   @s_user            login         = null,
   @s_term            descripcion   = null,
   @s_corr            char(1)       = null,
   @s_ssn_corr        int           = null,
   @s_ofi             smallint      = null,
   @s_culture         varchar(10)   = null,
   @t_rty             char(1)       = null,
   @t_trn             int           = null,
   @t_debug           char(1)       = 'N',
   @t_file            varchar(14)   = null,
   @t_from            varchar(30)   = null,
   @t_show_version    bit           = 0,
   @i_filial          smallint      = 1,
   @i_fecha           datetime      = null,
   @i_sarta           int           = 21000,
   @i_batch           int           = null,
   @i_secuencial      int           = null,
   @i_corrida         int           = null,
   @i_intento         int           = null,
   @i_param1          datetime      = null
)
as
declare @w_error               int,
        @w_return              int,
        @w_sp_name             varchar(30),
        @w_fecha_proc          datetime,
        @w_num_banco           cuenta,
        @w_fecha_vto           datetime,
        @w_num_dec             tinyint,
        @w_cotizacion          float,
        @w_linea               int,
        @w_secuencial          int,
        @w_fecha_tran          datetime,
        @w_transaccion         catalogo,
        @w_moneda              tinyint,
        @w_valor               float,
        @w_valor_ref           float,
        @w_estado              char(3),
        @w_operacion           int, 
        @w_oficina             smallint,
        @w_usuario             login,
        @w_terminal            varchar(30),
        @w_secuencial_ref      int,
        @w_tot_debito          money,
        @w_tot_credito         money,
        @w_tot_credito_me      money,
        @w_tot_debito_me       money,
        @w_mensaje             varchar(64),
        @w_moneda_nacional     int,
        @w_cuenta_final        varchar(20),
        @w_cuenta_debito       varchar(20),
        @w_debito              money,
        @w_credito             money,
        @w_perfil              catalogo,
        @w_cuenta_credito      varchar(20),
        @w_mon_cuenta          tinyint,
        @w_valor_me            money,
        @w_debito_me           money,
        @w_credito_me          money,
        @w_debcred             char(1),
        @w_mon_lin             tinyint,
        @w_moneda_a            tinyint,
        @w_comprobante         int,
        @w_sec_producto        varchar(12),
        @w_area_credito        int,
        @w_descripcion         varchar(255),
        @w_cliente             int,
        @w_grupo               int,
        @w_oficial             int,
        @w_oficial_tramite     int,
        @w_today               datetime,
        @w_pgroup              catalogo,
        @w_oficina_conta       smallint,
        @w_area_origen         smallint,
        @w_asiento             int,
        @w_tran                varchar(20),
        @w_compromiso          varchar(5),
        @w_revolutiva          char (1),
        @w_intercompany        varchar(20),
        @w_sp                  varchar(20),
        @w_area_destino        smallint,
        @w_linea_aux           varchar(10),
        @w_detalle             varchar(255),
        @w_retorno_ej          int,
        @w_moneda_aux          varchar(10),
        @w_toperacion          catalogo,
        @w_producto            tinyint,
        @w_fecha_dia           datetime,
        @w_op_banco            varchar(30),
        @w_num_comprobante     int,
        @w_num_asiento         int,
        @w_num_cuenta          varchar(14),
        @w_cod_ofi             smallint,
        @w_cod_area            int,
        @w_det_concepto        varchar(255),
        @w_cod_perfil          varchar(10),
        @w_valor_error         money,
        @w_lin_banco           varchar(30),
        @w_numero              int,
        @w_utilizado           money,
        @w_monto               money


-------------------------------------
-- Versionamiento del Programa 
-------------------------------------
if @t_show_version = 1
begin
   print 'Stored procedure sp_cancelacion_lc, Version 4.0.0.2'
   return 0
end

if @s_culture is null
begin
   exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out
end

select @w_sp_name  = 'sp_cancelacion_lc',
       @w_num_dec  = 2,
       @i_fecha = isnull(@i_fecha, getdate())
select @w_fecha_proc = isnull(fp_fecha, getdate()) from cobis..ba_fecha_proceso

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_area_origen = pa_tinyint 
from   cobis..cl_parametro
where  pa_producto = 'CRE'
and    pa_nemonico = 'CAORC'

select @w_area_destino = isnull(pa_int, @w_area_origen)
from   cobis..cl_parametro
where  pa_producto = 'CRE'
and    pa_nemonico = 'ACONCR'

select @w_today = fp_fecha
from   cobis..ba_fecha_proceso

if (OBJECT_ID('tempdb.dbo.#cr_cotiz3','U')) is not null
begin
   drop table #cr_cotiz3
end

CREATE TABLE #cr_cotiz3
(moneda      tinyint null,
 cotizacion  float   null)

insert into #cr_cotiz3(moneda, cotizacion)
select distinct
a.ct_moneda, a.ct_compra
from   cb_cotizaciones a
where  ct_fecha = (select max(b.ct_fecha)
                   from  cb_cotizaciones b
                   where b.ct_moneda = a.ct_moneda
                   and   b.ct_fecha <= @w_today)

-- insertar un registro para la moneda local
if not exists (select 1
               from #cr_cotiz3
               where moneda = @w_moneda_nacional)
   insert into #cr_cotiz3 (moneda, cotizacion)
   values (@w_moneda_nacional, 1)

declare cursor_ln cursor for
select li_numero, li_num_banco, li_fecha_vto,  isnull(li_utilizado, 0), li_monto, li_moneda  from cob_credito..cr_linea
where li_estado = 'V'
--and li_estado is not null
and cast(li_fecha_vto as date) < @w_fecha_proc

open cursor_ln
fetch next from cursor_ln into @w_numero, @w_num_banco, @w_fecha_vto, @w_utilizado, @w_monto, @w_moneda
while @@fetch_status = 0
begin
   if not exists (select 1 from cob_cartera..ca_operacion
                  where op_lin_credito = @w_num_banco
                  and op_estado not in (0, 3, 6, 99))
   begin  

	  select @w_valor  = (@w_monto - @w_utilizado) 
	   
	  if @w_valor > 0
      begin
	  
         begin tran	  
            update cob_credito..cr_linea
            set li_estado = 'C'
            where li_num_banco = @w_num_banco	  

            exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_ofi         = @s_ofi,
                 @s_term        = @s_term,
                 @t_trn         = 21450,
                 @i_transaccion = 'C',
                 @i_linea       = @w_numero,
                 @i_valor_ref   = @w_monto,
                 @i_valor       = @w_valor,
                 @i_moneda      = @w_moneda,
                 @i_estado      = 'I'

            if @w_return != 0
            begin
                 select @w_error = @w_return 
                 goto ERRADO
            end

            exec @w_return = sp_transacciones_linea
                 @s_user        = @s_user,
                 @s_date        = @s_date,
                 @s_term        = @s_term,
                 @s_ofi         = @s_ofi,
                 @t_trn         = 21469,
                 @i_transaccion = 'E',
                 @i_linea       = @w_numero,
                 @i_valor_ref   = @w_monto,				 
                 @i_valor       = @w_valor,
                 @i_moneda      = @w_moneda

            if @w_return != 0
            begin
               select @w_error = @w_return 
               goto ERRADO
            end
		 commit tran	
      end
	  
/*
      select @w_linea           = tl_linea,   
             @w_secuencial      = tl_secuencial, 
             @w_transaccion     = 'C',
             @w_moneda          = tl_moneda,
             @w_valor           = tl_valor,
             @w_estado          = tl_estado,
             @w_oficina         = tl_oficina,
             @w_usuario         = tl_usuario,
             @w_cliente         = li_cliente,
             @w_grupo           = li_grupo,
             @w_mon_lin         = li_moneda,
             @w_oficial_tramite = tr_oficial,
             @w_pgroup          = tl_pgroup

      from   cr_transaccion_linea, cr_linea, cr_tramite,  cr_det_transaccion_linea
      where  tl_linea       = dtl_linea
      and    tl_secuencial  = dtl_secuencial
      and    dtl_fecha_tran = tl_fecha_tran
      and    tl_linea       = li_numero
      and    li_tramite     = tr_tramite
      and    li_num_banco   = @w_num_banco
   
      if @w_moneda <> @w_moneda_nacional
      begin
         -- NUEVO MONTO DE LA LINEA DE CREDITO EN ML
         select @w_valor_me = @w_valor
   
         select @w_valor      = @w_valor * cotizacion, 
                @w_cotizacion = cotizacion
         from   #cr_cotiz3
         where  moneda = @w_moneda   
   
         if @@rowcount = 0
         begin
            select @w_error           = 2110246,
                   @w_moneda_aux      = convert(varchar(10),@w_moneda),
                   @w_detalle         = 'NO EXISTE COTIZACION MON:' + @w_moneda_aux + ' LIN:' + @w_linea_aux,
                   @w_op_banco        = '',
                   @w_num_comprobante = 0,
                   @w_num_asiento     = 0,
                   @w_num_cuenta      = '',
                   @w_cod_ofi         = @w_oficina,
                   @w_cod_area        = @w_area_origen,
                   @w_det_concepto    = '',
                   @w_cod_perfil      = '',
                   @w_valor_error     = @w_valor
   
            print 'error 1'
   
            goto ERRADO               
         end
      end
      else--@w_moneda <> @w_moneda_nacional
         select @w_valor_me = 0
   
      select @w_valor    = round (@w_valor,@w_num_dec),
             @w_valor_me = round (@w_valor_me,@w_num_dec)
   
      select @w_tot_debito     = 0.00,
             @w_tot_credito    = 0.00,
             @w_tot_debito_me  = 0.00,
             @w_tot_credito_me = 0.00,
             @w_mensaje        = ''
   
      --Obtengo el perfil de acuerdo al tipo de transaccion
      select @w_perfil = to_perfil
      from   cr_trn_oper
      where  to_tipo_trn = @w_transaccion
   
      if @@rowcount = 0
      begin   
         select @w_detalle         = 'CUENTA EXISTE PERFIL PARA LA TRAN: ' + @w_transaccion + ' LIN: ' + @w_linea_aux,
                @w_error           = 701148, ---No existe perfil contable
                @w_op_banco        = '',
                @w_num_comprobante = 0,
                @w_num_asiento     = 0,
                @w_num_cuenta      = '',
                @w_cod_ofi         = @w_oficina,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = '',
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor_me
   
         print '2'
         goto ERRADO         
      end       
   
      select @w_oficial = @w_oficial_tramite
      
      --Variable revolutiva
      select @w_revolutiva = rtrim(ltrim(li_rotativa)),
             @w_toperacion = rtrim(ltrim(li_tipo)),
             @w_lin_banco  = li_num_banco
      from   cr_linea
      where  li_numero = @w_linea
      
      --Obtengo la cuenta de debito para el perfil seleccionado     
      select @w_descripcion = @w_lin_banco + ' | ' + rtrim(convert(char(24),@w_secuencial)) + ' | ' + rtrim(pe_descripcion) + ' | ' + 
                              (case @w_transaccion when 'A' then 'AUMENTO'
                                                   when 'D' then 'DISMINUCION'
                                                   when 'V' then 'VIGENCIA'
                                                   when 'C' then 'CANCELACION' end),
             @w_cuenta_debito = rtrim(ltrim(dp_cuenta))
      from   cob_conta..cb_det_perfil,cob_conta..cb_perfil
      where  dp_empresa   = @i_filial
      and    dp_producto  = 21
      and    dp_perfil    = @w_perfil
      and    pe_empresa   = @i_filial
      and    pe_producto  = 21
      and    pe_perfil    = @w_perfil
      and    dp_empresa   = pe_empresa
      and    dp_producto  = pe_producto
      and    dp_perfil    = pe_perfil
      and    dp_debcred   = '1'
   
      if @@rowcount = 0      
      begin
         select @w_detalle         = 'CUENTA DE DEBITO NO EXISTE PARA PERFIL: ' + @w_perfil  + ' LIN:' + @w_linea_aux,
                @w_error           = 190100,---No existe perfil contable
                @w_asiento         = 0,
                @w_op_banco        = '',
                @w_num_comprobante = 0,
                @w_num_asiento     = 0,
                @w_num_cuenta      = '',
                @w_cod_ofi         = @w_oficina,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = '',
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor_me
   
         print '3'
         goto ERRADO
      end
   
      --Obtengo la cuenta de credito para el perfil seleccionado 
      select @w_cuenta_credito = dp_cuenta
      from   cob_conta..cb_det_perfil,cob_conta..cb_perfil
      where  dp_empresa   = @i_filial
      and    dp_producto  = 21
      and    dp_perfil    = @w_perfil
      and    pe_empresa   = @i_filial
      and    pe_producto  = 21
      and    pe_perfil    = @w_perfil
      and    dp_empresa   = pe_empresa 
      and    dp_producto  = pe_producto
      and    dp_perfil    = pe_perfil    
      and    dp_debcred   = '2' 
   
      if @@rowcount = 0
      begin
         select @w_detalle         = 'CUENTA DE CREDITO NO EXISTE PARA PERFIL: ' + @w_perfil  + ' LIN:' + @w_linea_aux,
                @w_error           = 2110245,---No existe perfil contable
                @w_asiento         = 0,
                @w_op_banco        = '',
                @w_num_comprobante = 0,
                @w_num_asiento     = 0,
                @w_num_cuenta      = '',
                @w_cod_ofi         = @w_oficina,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = '',
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor_me
   
         print '4'
         goto ERRADO
      end
   
      select @w_oficina_conta =  re_ofconta 
      from   cob_conta..cb_relofi
      where  re_ofadmin = @w_oficina
   
      if @@rowcount = 0
      begin
            select @w_detalle         = 'OFICINA: ' + convert(varchar,@w_oficina) + 'NO TIENE EQUIVALENTE EN CB_RELOFI' + ' LIN:' + @w_linea_aux,
                   @w_error           = 2110246,
                   @w_asiento         = 0,
                   @w_op_banco        = '',
                   @w_num_comprobante = 0,
                   @w_num_asiento     = @w_asiento,
                   @w_num_cuenta      = '',
                   @w_cod_ofi         = @w_oficina,
                   @w_cod_area        = @w_area_origen,
                   @w_det_concepto    = '',
                   @w_cod_perfil      = @w_perfil,
                   @w_valor_error     = @w_valor_me
   
         print '5'
         goto ERRADO
      end

      begin tran

      -- Genera los comprobantes
      select @w_asiento = 2
   
      exec @w_return         = cob_conta..sp_scomprobante
           @i_operacion      = 'I',
           @i_modo           = 0,
           @i_producto       = 21,
           @i_empresa        = @i_filial,
           @i_fecha_tran     = @i_fecha,
           @i_oficina_orig   = @w_oficina_conta,
           @i_area_orig      = @w_area_origen, --@w_oficial,
           --@i_fecha_gra      = @i_fecha,
           @i_digitador      = @w_usuario,
           @i_descripcion    = @w_descripcion,
           @i_perfil         = @w_perfil,
           @i_detalles       = @w_asiento, --2,
           @i_tot_debito     = @w_valor,
           @i_tot_credito    = @w_valor,
           @i_tot_debito_me  = @w_valor_me,
           @i_tot_credito_me = @w_valor_me,
           @i_automatico     = 0,
           @i_reversado      = 'N',
           @i_estado         = 'I',
           @o_comprobante    = @w_comprobante out
   
      if @w_return !=0 
      begin
         select @w_detalle         = 'ERROR AL EJECUTAR SP_SCOMPROBANTE FECHA: ' + convert(varchar,@i_fecha) + 'PERFIL: ' + @w_perfil + 'ASIENTO: ' + convert(varchar,@w_asiento) + 'OFICINA: ' + convert(varchar,@w_oficina_conta)+ ' LIN:' + @w_linea_aux,
                @w_error           = @w_return,
                @w_asiento         = @w_asiento,
                @w_op_banco        = '',
                @w_num_comprobante = 0,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = '',
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
   
         print '6'
         goto ERRADO
      end
       
      -- GENERACION DEL ASIENTO DE DEBITO
      select @w_cuenta_final = '',
             @w_mon_cuenta   = null
   
      select @w_sp = rtrim(ltrim(pa_stored))
      from   cob_conta..cb_parametro       
      where  pa_parametro = @w_cuenta_debito
   
      if @@rowcount = 0 
      begin
         select @w_detalle         = 'NO EXISTE PARAMETRO PARA LA CUENTA '+ @w_cuenta_debito+ 'LIN:' + @w_linea_aux,
                @w_error           = 2110243 ,
                @w_asiento         = 0,
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
            
         print '7'
         goto ERRADO
      end
   
      select @w_cuenta_final = re_substring
      from   cob_conta..cb_relparam
      where  re_parametro           = @w_cuenta_debito
      and    rtrim(ltrim(re_clave)) = @w_moneda
   
      if @@rowcount = 0 
      begin
         --print '@w_sp %1!  @w_toperacion %2!  @w_moneda %3! @w_revolutiva %4! ', @w_sp, @w_toperacion, @w_moneda, @w_revolutiva
         select @w_detalle         = 'NO EXISTE CUENTA EN cb_relparam PARA EL STRING: '+ @w_cuenta_debito + ' LIN:' + @w_linea_aux,
                @w_error           = 2110244 ,--No existe cuenta
                @w_asiento         = 0,
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
            
         print '8'
         goto ERRADO
      end  
   
      select @w_mon_cuenta = cu_moneda 
      from   cob_conta..cb_cuenta
      where  cu_empresa = @i_filial
      and    cu_cuenta  = @w_cuenta_final
   
      if @@rowcount = 0
      begin
         select @w_detalle         = 'NO SE PUDO RESOLVER CUENTA: ' + @w_cuenta_debito + 'PARA MONEDA: ' + convert(varchar,@w_moneda) + 'PRODUCT GRUOUP: ' + @w_pgroup + ' LIN:' + @w_linea_aux,
                @w_error           = 2110245,--No existe cuenta
                @w_asiento         = 0, 
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
         
         print '9'
         goto ERRADO
      end
   
      select @w_debito = @w_valor
    
      select @w_debito     = round (@w_debito,@w_num_dec),
             @w_debito_me  = round (@w_valor_me,@w_num_dec),
             @w_credito    = 0,
             @w_credito_me = 0,
             @w_debcred    = '1',
             @w_moneda_a   = @w_moneda
   
      if @w_mon_cuenta = @w_moneda_nacional
        select @w_moneda_a   = @w_moneda_nacional,
               @w_debito_me  = 0,
               @w_credito_me = 0
   
      -- REGISTRAR PRIMER ASIENTO
      select @w_asiento = 1 
   
      exec @w_return         = cob_conta..sp_sasiento 
           @i_operacion      = 'I',
           @i_fecha_tran     = @i_fecha,
           @i_comprobante    = @w_comprobante,
           @i_empresa        = @i_filial,
           @i_asiento        = @w_asiento, --1,
           @i_cuenta         = @w_cuenta_final,
           @i_oficina_dest   = @w_oficina_conta, 
           @i_area_dest      = @w_area_destino, 
           @i_credito        = @w_credito,
           @i_debito         = @w_debito,
           @i_concepto       = @w_descripcion,  --CAMBIAR DESCRIPCION 'DEBITO A LA CUENTA ..'
           @i_credito_me     = @w_credito_me,
           @i_debito_me      = @w_debito_me,
           @i_moneda         = @w_moneda_a,
           @i_cotizacion     = @w_cotizacion,
           @i_tipo_doc       = 'N',
           @i_tipo_tran      = 'N',
           @i_producto       = 21,
           @i_debcred        = @w_debcred   
   
      if @w_return !=0 
      begin
         select @w_detalle         = 'ERROR AL EJECUTAR SP_SASIENTO, FECHA: ' + convert(varchar,@i_fecha)  + 'CUENTA: ' + @w_cuenta_final + ' LIN:' + @w_linea_aux,
                @w_error           = @w_return,
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
            
         print '10'
         goto ERRADO
      end
   
      select @w_tot_debito     = @w_tot_debito + @w_debito,
             @w_tot_credito    = @w_tot_credito + @w_credito,
             @w_tot_debito_me  = @w_tot_debito_me  + @w_debito_me,
             @w_tot_credito_me = @w_tot_credito_me + @w_credito_me
   
      -- GENERACION DE ASIENTO DE CREDITO
      select @w_cuenta_final = '',
             @w_mon_cuenta   = null
   
      select @w_cuenta_final = re_substring
      from   cob_conta..cb_relparam
      where  re_parametro = @w_cuenta_credito
      and    re_clave     = @w_moneda
   
      if @@rowcount = 0 
      begin
         --print '@w_sp %1!  @w_toperacion %2!  @w_moneda %3! @w_revolutiva %4! ', @w_sp, @w_toperacion, @w_moneda, @w_revolutiva
         select @w_detalle         = 'NO EXISTE CUENTA EN cb_relparam PARA EL STRING: '+ @w_cuenta_debito+ ' LIN:' + @w_linea_aux,
                @w_error           = 2110244 ,--No existe cuenta
                @w_asiento         = 0,
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
   
         print '11'
         goto ERRADO
      end
   
      select @w_mon_cuenta = cu_moneda 
      from   cob_conta..cb_cuenta
      where  cu_empresa = @i_filial
      and    cu_cuenta  = @w_cuenta_final
   
      if @@rowcount = 0
      begin
         select @w_detalle         = 'NO SE PUDO RESOLVER CUENTA: ' + @w_cuenta_debito + 'PARA MONEDA: ' + convert(varchar,@w_moneda) + 'PRODUCT GRUOUP: ' + @w_pgroup + ' LIN:' + @w_linea_aux,
                @w_error           = 2110245,--No existe cuenta
                @w_asiento         = 0, 
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
   
         print '12'
         goto ERRADO
      end
   
      select @w_credito = @w_valor
   
      select @w_debito     = 0.00,
             @w_debito_me  = 0.00,
             @w_credito    = round(@w_credito,@w_num_dec),
             @w_credito_me = round (@w_valor_me,@w_num_dec),
             @w_debcred    = '2',
             @w_moneda_a   = @w_moneda
   
      if @w_mon_cuenta = @w_moneda_nacional
         select @w_moneda_a   = @w_moneda_nacional,
                @w_debito_me  = 0,
                @w_credito_me = 0
   
      --REGISTRAR SEGUNDO ASIENTO
      select @w_asiento = 2
   
      exec @w_return         = cob_conta..sp_sasiento 
           @i_operacion      = 'I',
           @i_fecha_tran     = @i_fecha,
           @i_comprobante    = @w_comprobante,
           @i_empresa        = @i_filial,
           @i_asiento        = @w_asiento, --2,
           @i_cuenta         = @w_cuenta_final,
           @i_oficina_dest   = @w_oficina_conta,
           @i_area_dest      = @w_area_destino,
           @i_credito        = @w_credito,
           @i_debito         = @w_debito,
           @i_concepto       = @w_descripcion,
           @i_credito_me     = @w_credito_me,
           @i_debito_me      = @w_debito_me,
           @i_moneda         = @w_moneda_a,
           @i_cotizacion     = @w_cotizacion,
           @i_tipo_doc       = 'N',
           @i_tipo_tran      = 'N',
           @i_producto       = 21,
           @i_debcred        = @w_debcred
   
      if @w_return !=0 
      begin
         select @w_detalle         = 'ERROR AL EJECUTAR SP_SASIENTO, FECHA: ' + convert(varchar,@i_fecha)  + 'CUENTA: ' + @w_cuenta_final + ' LIN:' + @w_linea_aux,
                @w_error           = @w_return,
                @w_op_banco        = '',
                @w_num_comprobante = @w_comprobante,
                @w_num_asiento     = @w_asiento,
                @w_num_cuenta      = @w_cuenta_final,
                @w_cod_ofi         = @w_oficina_conta,
                @w_cod_area        = @w_area_origen,
                @w_det_concepto    = @w_descripcion,
                @w_cod_perfil      = @w_perfil,
                @w_valor_error     = @w_valor
   
         print '13'
         goto ERRADO
      end
   
      commit tran
	  */
   end    
   fetch next from cursor_ln into @w_numero, @w_num_banco, @w_fecha_vto, @w_utilizado, @w_monto, @w_moneda
end

close cursor_ln
deallocate cursor_ln

return 0

ERRADO:
   print 'Entrando a error'
   update cob_credito..cr_linea
   set li_estado = 'V'
   where li_num_banco = @w_num_banco

   while @@trancount > 0
      rollback tran
   
   close cursor_ln
   deallocate cursor_ln

   exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = @w_error,
      @s_culture  = @s_culture
   return @w_error

go
