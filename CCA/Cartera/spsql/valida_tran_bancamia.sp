/************************************************************************/
/*	 Nombre Fisico:		   valida_tran_bancamia.sp						*/
/*   NOmbre Logico:        sp_valida_transacciones_bancamia             */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
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
/*                            PROPOSITO                                 */
/************************************************************************/
/*							Modificaciones								*/
/*		Fecha			Autor				Razon						*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_valida_transacciones_bancamia')
   drop proc sp_valida_transacciones_bancamia
go
 
 
CREATE proc [dbo].[sp_valida_transacciones_bancamia] (
   @i_fecha    smalldatetime
)
as
 
declare 
/*variables para validacion de la tabla ca_transaccion*/
@w_tr_secuencial       int,
@w_tr_fecha_mov        smalldatetime,
@w_tr_toperacion       varchar(10),
@w_tr_moneda           tinyint,
@w_tr_operacion        int,
@w_tr_tran             varchar(10),
@w_tr_en_linea         varchar(1),
@w_tr_banco            varchar(24),
@w_tr_dias_calc        int,
@w_tr_ofi_oper         smallint,
@w_tr_ofi_usu          smallint,
@w_tr_usuario          varchar(14),
@w_tr_terminal         varchar(30),
@w_tr_fecha_ref        smalldatetime,
@w_tr_secuencial_ref   int,
@w_tr_estado           varchar(10),
@w_tr_observacion      varchar(62),
@w_tr_gerente          smallint,
@w_tr_comprobante      int,
@w_tr_fecha_cont       datetime,
@w_tr_gar_admisible    char(1),
@w_tr_reestructuracion char(1),
@w_tr_calificacion     catalogo,
@w_tr_fecha_real       datetime,
 
/*variables para validacion de la tabla ca_det_trn*/
@w_dtr_secuencial      int,
@w_dtr_banco           varchar(26),
@w_dtr_dividendo       int,
@w_dtr_concepto        varchar(30),  -- FYA antes catalogo
@w_dtr_estado          tinyint,
@w_dtr_periodo         tinyint,
@w_dtr_codvalor        int,
@w_dtr_monto           money,
@w_dtr_monto_mn        money,
@w_dtr_moneda          tinyint,
@w_dtr_cotizacion      float,
@w_dtr_tcotizacion     char(1),
@w_dtr_afectacion      char(1),
@w_dtr_cuenta          varchar(20),
@w_dtr_beneficiario    varchar(64),
@w_dtr_monto_cont      money,
 
@w_cod_valor           int,
@w_fecha_proceso       datetime,
@w_descripcion         varchar(255),
@w_es_error            char(1),      --  FYA 05NOV2008 
@w_es_error_det        char(1),      --  FYA 05NOV2008 
@w_homologar           char(1),      --  FYA 05NOV2008 
@w_tr_ofi_oper_aux     varchar(4),   --  FYA 05NOV2008 
@w_tr_ofi_usu_aux      varchar(4),   --  FYA 05NOV2008 
@w_dtr_concepto_aux    varchar(30),
@w_cod_ofi_err         int,     --  FYA 09NOV2008 
@w_cod_rubo_err        catalogo,     --  FYA 09NOV2008 
@w_cod_fpag_err        catalogo,      --  FYA 09NOV2008 
@w_contador            int,
@w_total               int,
@w_concepto            varchar(30),
@w_concepto_cobis      varchar(30),
@w_estado              smallint,
@w_afectacion          char(1),
@w_mensaje             varchar(255),
@w_error               int,
@w_sp_name             varchar(64),
@w_max_bm              int,
@w_max_tmp             int,
@w_fp_ajmen            catalogo,
@w_fp_ajmay            catalogo,
@w_cv_ajmen            int,
@w_cv_ajmay            int,
@w_limite              money,
@w_count               int,
@w_oficina_c           varchar(4)

truncate table ca_transaccion_bancamia_2
truncate table ca_det_trn_bancamia_2

select 
@w_homologar   = 'S',
@w_contador    =  0,
@w_total       =  0,
@w_cod_ofi_err = 4003,   -- SI NO EXISTE LA OFICINA SE FORZA ALA 4003
@w_sp_name     = 'sp_valida_transacciones_bancamia',
@w_limite      = 5000

/*CODIGO DE RUBROS Y FORMAS DE PAGO NO MOLOGADAS*/

select @w_cod_rubo_err    = ho_texto   
from ca_homologa_otros_pag 
where ho_oficina = 'ERROR'
and   ho_tipo    = 'C'
 
select @w_cod_fpag_err     = ho_texto  
from ca_homologa_otros_pag 
where ho_oficina = 'ERROR'
and   ho_tipo    = 'FP'
 
select @w_cv_ajmen = cp_codvalor,
       @w_fp_ajmen = cp_producto
from ca_producto_bancamia
where cp_producto = 'AJUSTE_MEN'


select @w_cv_ajmay = cp_codvalor,
       @w_fp_ajmay = cp_producto
from ca_producto_bancamia
where cp_producto = 'AJUSTE_MAY'


select * into #trn_dup
from ca_det_trn_bancamia_tmp
where 1=2


select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso


/* DETERMINAR LA ULTIMA FECHA EN QUE FUERON REPORTADAS LAS OPERACIONES CON TRANSACCIONES A VALIDAR */ 
select banco = do_banco, fecha = max(do_fecha)
into #max_fecha
from cob_conta_super..sb_dato_operacion, ca_transaccion_bancamia_tmp
where do_banco = tr_banco
group by do_banco

/* DETERMINAR LA OFICINA CON QUE FUERON REPORTADAS LAS OPERACIONES */
select do_banco, do_oficina
into #dato_operacion
from cob_conta_super..sb_dato_operacion, #max_fecha
where do_banco = banco
and   do_fecha = fecha


/* ACTULIZAR DATOS FIJOS */
 
update ca_det_trn_bancamia_tmp set
dtr_monto_mn    = dtr_monto,
dtr_moneda      = 0,      
dtr_cotizacion  = 1.0,  
dtr_tcotizacion = 'C', 
--dtr_cuenta      = '0',      
dtr_monto_cont  = 0,  
dtr_periodo     = 0
where dtr_banco      > ''
and   dtr_secuencial > 0
and   dtr_codvalor   = 0
 
 
update ca_det_trn_bancamia_tmp set
dtr_estado = 1
where dtr_banco      > ''
and   dtr_secuencial > 0
and   dtr_estado is null



/* HOMOLOGAR  */
if @w_homologar = 'S' begin

   /* HOMOLOGAR CONCEPTOS */
   declare cursor_concepto cursor  fast_forward for
   select distinct(dtr_concepto) 
   from   ca_det_trn_bancamia_tmp 
 
   open  cursor_concepto
   fetch cursor_concepto
   into  @w_concepto
 
   while @@fetch_status = 0  begin
 
      select @w_concepto_cobis = ho_texto
      from   ca_homologar
      where  ho_tabla      = 'rubros'
      and    ho_codigo_org = @w_concepto
      and    ho_tipo       = 'T'

      if @@rowcount = 0 begin
         if exists (select 1 from ca_concepto_bancamia where co_concepto = @w_concepto)
            select @w_concepto_cobis = @w_concepto
         else
            select @w_concepto_cobis = @w_cod_rubo_err
      end


      /* DETERMINAR CODIGO VALOR SUPONIENDO QUE EL CONCEPTO ES UNA FORMA DE PAGO */
      select @w_cod_valor = cp_codvalor
      from   ca_producto_bancamia
      where  cp_producto = @w_concepto_cobis
 
      if @@rowcount = 0 begin --no es una forma de pago, es un rubro

         select @w_cod_valor = co_codigo * 1000 
         from   ca_concepto_bancamia
         where  co_concepto = @w_concepto_cobis

         if @@rowcount = 0 begin

            select @w_mensaje = 'ERR: En seleccion codvalor ca_concepto_bancamia ' + @w_concepto_cobis
            select @w_error = 7201
            goto ERROR1
         end

         --print '@w_concepto: '  + cast(@w_concepto as varchar)
         --print '@w_cod_valor: ' + cast(@w_cod_valor as varchar)
         --print '@w_concepto_cobis : ' + cast(@w_concepto_cobis as varchar)

         update ca_det_trn_bancamia_tmp set
         dtr_codvalor     = @w_cod_valor + cast(dtr_estado as int)* 10,
         dtr_concepto     = @w_concepto_cobis,
         dtr_beneficiario = substring(ltrim(rtrim(dtr_beneficiario)) + ' ' + ltrim(rtrim(@w_concepto)), 1, 64)
         where dtr_concepto   = @w_concepto

         if @@error <> 0 begin
            print 'Error: ' + cast(@@error as varchar)
            select @w_mensaje = 'ERR: En actualizar codvalor ca_det_bancamia_tmp ' + cast(@w_cod_valor as varchar)
            select @w_error = 7202
            goto ERROR1
         end

      end else begin

         update ca_det_trn_bancamia_tmp set
         dtr_codvalor     = @w_cod_valor,
         dtr_concepto     = @w_concepto_cobis,
         dtr_beneficiario = substring(ltrim(rtrim(dtr_beneficiario)) + ' ' + ltrim(rtrim(@w_concepto)), 1, 64)
         where dtr_concepto   = @w_concepto

         if @@error <> 0 begin
            select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  ' + cast(@w_cod_valor as varchar)
            select @w_error = 7203
            goto ERROR1
         end

      end
 
      goto SIGUIENTE1


      ERROR1:


      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = @w_error, 
      @i_usuario     = 'car_bach',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'CONTABILIDAD', 
      @i_descripcion = @w_mensaje

      SIGUIENTE1:

      fetch cursor_concepto into  @w_concepto
 
   end -- Fin cursor cursor_concepto
 
   close cursor_concepto
   deallocate cursor_concepto






   update ca_transaccion_bancamia_tmp set 
   tr_ofi_usu =  convert (varchar(20),do_oficina)
   from #dato_operacion
   where do_banco    = tr_banco
   and   tr_ofi_oper in ('1199','0530')

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: AL RESTAURAR OFICINA ORIGINAL EN OPERACIONES CASTIGADAS  '
      select @w_error = 7200
      goto ERRORFIN
   end 

   update ca_transaccion_bancamia_tmp set 
   tr_ofi_usu     =  convert (varchar(20),do_oficina),
   tr_observacion = 'ERR: OPERACION MAL MIGRADA CODIGO OFICINA USUARIO '
   from #dato_operacion
   where do_banco     = tr_banco
--   and   tr_ofi_usu in ('D 21','D 22','F','F  1','B 19','C  9')
   and 0 = ( CASE
                 WHEN LEFT(tr_ofi_usu,1) LIKE '[-0-9+.]'
                        AND PATINDEX('%[^0-9.]%', SUBSTRING(tr_ofi_usu, 2, 18)) = 0
                        AND LEN(tr_ofi_usu) - LEN(REPLACE(tr_ofi_usu, '.', '')) <=1  THEN
                    1
                 ELSE
                    0
             END)

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: OPERACION MAL MIGRADA CODIGO OFICINA USUARIO '
      select @w_error = 7200
      goto ERRORFIN
   end 
 
   /*RUTINA DE ERROR*/
   if exists ( select 1 from ca_transaccion_bancamia_tmp 
   where tr_fecha_mov > @i_fecha)
   begin
      
      exec cob_cartera..sp_errorlog
      @i_fecha       = @i_fecha, 
      @i_error       = 7200, 
      @i_usuario     = 'opbatch',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = '', 
      @i_descripcion = 'EXISTEN TRANSACCIONES CON FECHA MAYOR A FECHA PROCESO'
 
      update ca_transaccion_bancamia_tmp set
      tr_operacion       = 999
      where tr_fecha_mov > @i_fecha
      if @@error <> 0 begin
         select @w_mensaje = 'ERR: En actualizar ca_transaccion_bancamia_tmp por fproceso < '
         select @w_error = 7200
         goto ERROR2
      end

      update ca_det_trn_bancamia_tmp set
      dtr_dividendo    = 999
      from  ca_transaccion_bancamia_tmp
      where dtr_banco      = tr_banco
      and   dtr_secuencial = tr_secuencial
      and   tr_fecha_mov   > @i_fecha


      if @@error <> 0 begin
         select @w_mensaje = 'ERR: En actualizar ca_transaccion_bancamia_tmp por fproceso < '
         select @w_error = 7200
         goto ERROR2
      end
   end

/*
-- SE COMENTA POR CARGUE MASIVO A 31
-- PARA CARGUES DIARIOS POSTERIORES SE DEBE ACTIVAR ESTE BLOQUE DE CODIGO
   
   if exists ( select 1 from ca_transaccion_bancamia_tmp 
   where tr_fecha_mov < @i_fecha)
   begin
      select fecha_mov=tr_fecha_mov, ofi_oper = tr_ofi_oper, banco = tr_banco, secuencial = tr_secuencial
      into #dat_ofi
      from ca_transaccion_bancamia_tmp
      where tr_fecha_mov < @i_fecha

      delete #dat_ofi
      from cob_conta_super..sb_novedades_nocobis
      where ni_fecha_proceso = fecha_mov
      and   ni_oficina_cob   = ofi_oper
      and   ni_novedad       = 'NO EXISTEN SALDOS PARA LA OFICINA'

      if exists ( select 1 from #dat_ofi ) begin
         exec cob_cartera..sp_errorlog
         @i_fecha       = @i_fecha, 
         @i_error       = 7200, 
         @i_usuario     = 'opbatch',
         @i_tran        = 7000, 
         @i_tran_name   = @w_sp_name, 
         @i_rollback    = 'N',
         @i_cuenta      = '', 
         @i_descripcion = 'EXISTEN TRANSACCIONES CON FECHA MENOR A FECHA PROCESO'
 
         update ca_transaccion_bancamia_tmp 
         set
         tr_operacion       = 999,
         tr_observacion     = 'REGISTRO NO VALIDO - FECHA DE REGISTRO MENOR A FECHA DE PROCESO'
         from #dat_ofi
         where tr_banco      = banco
         and   tr_secuencial = secuencial
         if @@error <> 0 begin
            select @w_mensaje = 'ERR: En actualizar ca_transaccion_bancamia_tmp por fproceso > '
            select @w_error = 7200  
            goto ERROR2
         end

         update ca_det_trn_bancamia_tmp set
         dtr_dividendo    = 999
         from  #dat_ofi
         where dtr_banco      = banco
         and   dtr_secuencial = secuencial

         if @@error <> 0 begin
            select @w_mensaje = 'ERR: En actualizar ca_transaccion_bancamia_tmp por fproceso > '
            select @w_error = 7200
            goto ERROR2
         end
      end
   end
*/

   /* CONTROL ERRORES POR MONTOS NULOS */
   select distinct banco=dtr_banco, secuencial = dtr_secuencial
   into #montos_nulos
   from cob_cartera..ca_det_trn_bancamia_tmp 
   where dtr_monto is null

   update ca_transaccion_bancamia_tmp set
   tr_operacion    = 999,
   tr_observacion  = 'ERR: TRANSACCION CON DETALLES DE MONTOS EN NULL'
   from #montos_nulos
   where tr_banco     = banco
   and   tr_secuencial = secuencial

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: En actualizar transacciones con montos nulos  '
      select @w_error = 7205
      goto ERROR2
   end
 
   update ca_det_trn_bancamia_tmp set
   dtr_dividendo    = 999
   from  #montos_nulos
   where dtr_banco      = banco
   and   dtr_secuencial = secuencial

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: En actualizar detalle de transacciones con montos nulos  '
      select @w_error = 7206
      goto ERROR2
   end

   --insercion en ca_errorlog
   if exists(select 1 from #montos_nulos) begin
      insert into ca_errorlog (
      er_fecha_proc,   er_error,   er_usuario,
      er_tran,         er_cuenta,  er_descripcion,
      er_anexo)
      select 
      @i_fecha,        7200,       'crebatch',
      7000,            banco,      'ERR: TRANSACCION CON DETALLES DE MONTOS EN NULL',
      ''
      from #montos_nulos
   end
   

   /* CONTROL ERRORES POR OFICINAS */
   select distinct ofi=tr_ofi_usu
   into #ofi_err
   from cob_cartera..ca_transaccion_bancamia_tmp 
   where 0 = ( CASE
                    WHEN LEFT(tr_ofi_usu,1) LIKE '[-0-9+.]'
                           AND PATINDEX('%[^0-9.]%', SUBSTRING(tr_ofi_usu, 2, 18)) = 0
                           AND LEN(tr_ofi_usu) - LEN(REPLACE(tr_ofi_usu, '.', '')) <=1  THEN
                       1
                    ELSE
                       0
                END)

   update ca_transaccion_bancamia_tmp set
   tr_operacion    = 999,
   tr_observacion  = 'ERR: OPERACION MAL MIGRADA CODIGO OFICINA USUARIO '
   from #ofi_err 
   where tr_banco      > ''
   and   tr_secuencial > 0
   --and   tr_ofi_usu in ('D 21','D 22','F','F  1','B 19')
   --and isnumeric(tr_ofi_usu) = 0
   and tr_ofi_usu = ofi

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
      select @w_error = 7205
      goto ERROR2
   end
 

   update ca_det_trn_bancamia_tmp set
   dtr_dividendo    = 999
   from  ca_transaccion_bancamia_tmp, #ofi_err 
   where dtr_banco      = tr_banco
   and   dtr_secuencial = tr_secuencial
   and   tr_operacion   = 999 
   --and   tr_ofi_usu in ('D 21','D 22','F','F  1','B 19')
   --and isnumeric(tr_ofi_usu) = 0
   and tr_ofi_usu = ofi

   if @@error <> 0 begin
      select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
      select @w_error = 7206
      goto ERROR2
   end


   /* HOMOLOGAR OFICINAS */
   declare cursor_oficinas cursor fast_forward for
   select distinct(tr_ofi_usu) 
   from   ca_transaccion_bancamia_tmp (nolock)
   where  tr_operacion <> 999

   for read only
 
   open  cursor_oficinas
   fetch cursor_oficinas
   into  @w_oficina_c
 
   while @@fetch_status = 0 begin

      select @w_tr_ofi_oper = ho_entero
      from   ca_homologar
      where  ho_tabla      = 'oficinas'
      and    ho_codigo_org = @w_oficina_c
      and    ho_tipo       = 'E'
 
      if @@rowcount = 0 begin
         if exists (select 1 from cobis..cl_oficina where convert(varchar(10),of_oficina) = @w_oficina_c)
         begin
            goto SIGUIENTE2
         end

         select @w_descripcion = @w_descripcion + 'Err. Homologa Ofi ( '+ @w_oficina_c + '), '

         update ca_transaccion_bancamia_tmp set
         tr_operacion    = 999,
         tr_observacion  = substring(@w_descripcion,1,62)
         where tr_banco      > ''
         and   tr_secuencial > 0
         and  (tr_ofi_oper   = @w_oficina_c or tr_ofi_usu = @w_oficina_c)

         if @@error <> 0 begin
            rollback tran     
            select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
            select @w_error = 7205
            goto ERROR2
         end
 
         update ca_det_trn_bancamia_tmp set
         dtr_dividendo    = 999
         from  ca_transaccion_bancamia_tmp
         where dtr_banco      = tr_banco
         and   dtr_secuencial = tr_secuencial
         and   tr_operacion   = 999 
         and  (tr_ofi_oper    = @w_oficina_c or tr_ofi_usu = @w_oficina_c )

         if @@error <> 0 begin
            rollback tran
            select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
            select @w_error = 7206
            goto ERROR2
         end

      end
 
      goto SIGUIENTE2


      ERROR2:

      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = @w_error, 
      @i_usuario     = 'car_bach',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'CONTABILIDAD', 
      @i_descripcion = @w_mensaje

      SIGUIENTE2:
 
      fetch cursor_oficinas into  @w_oficina_c

   end -- Fin cursor cursor_oficinas
 
   close cursor_oficinas
   deallocate cursor_oficinas
 

   /* VALIDAR ESTADOS DE RUBROS */
   declare cursor_estados cursor  fast_forward for
   select distinct(dtr_estado)
   from   ca_det_trn_bancamia_tmp (nolock)
   where  dtr_estado not in (1,2,4,9)
     and  dtr_dividendo <> 999
   for read only
 
   open  cursor_estados 

   fetch cursor_estados into  @w_estado
 
   while @@fetch_status = 0  begin


      select @w_descripcion = @w_descripcion + 'Err. Estado no permitido ( '+ cast(@w_estado as varchar) + '), '
 
      update ca_det_trn_bancamia_tmp set
      dtr_dividendo    = 999
      where dtr_banco      > ''
      and   dtr_secuencial > 0
      and   dtr_estado     =  @w_estado

      if @@error <> 0 begin
         select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
         select @w_error = 7208
         goto ERROR3
      end
 
      update ca_transaccion_bancamia_tmp set
      tr_operacion    = 999,
      tr_observacion  = substring(@w_descripcion,1,62)
      from  ca_det_trn_bancamia_tmp
      where dtr_banco      = tr_banco
      and   dtr_secuencial = tr_secuencial
      and   tr_banco       > ''
      and   tr_secuencial  > 0
      and   dtr_estado     =  @w_estado

      if @@error <> 0 begin
         select @w_mensaje = 'ERR: En actualizar cod_valor ca_det_bancamia_tmp  '
         select @w_error = 7209
         goto ERROR3
      end
 
      goto SIGUIENTE3

      ERROR3:
      rollback tran     

      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = @w_error, 
      @i_usuario     = 'car_bach',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'CONTABILIDAD', 
      @i_descripcion = @w_mensaje

      SIGUIENTE3:
 
      fetch cursor_estados into  @w_estado

   end -- Fin cursor cursor_estados
 
   close cursor_estados
   deallocate cursor_estados

end


 
/* PROCESAR VALIDACIONES POR OPERACION */
declare cursor_transacciones cursor  fast_forward for
select tr_secuencial,    tr_fecha_mov,   tr_toperacion,    tr_moneda,      tr_operacion,     tr_tran,             tr_en_linea,       tr_banco,
       tr_dias_calc,     tr_ofi_oper,    tr_ofi_usu,       tr_usuario,     tr_terminal,      tr_fecha_ref,        tr_secuencial_ref, tr_estado,
       tr_observacion,   tr_gerente,     tr_comprobante,   tr_fecha_cont,  tr_gar_admisible, tr_reestructuracion, tr_calificacion,   tr_fecha_real
from   ca_transaccion_bancamia_tmp
where  tr_operacion  <> 999
order  by tr_banco, tr_secuencial
       for read only
        
open  cursor_transacciones
fetch cursor_transacciones
into  @w_tr_secuencial,    @w_tr_fecha_mov,    @w_tr_toperacion,   @w_tr_moneda,      @w_tr_operacion,     @w_tr_tran,             @w_tr_en_linea,       @w_tr_banco,
      @w_tr_dias_calc,     @w_tr_ofi_oper_aux, @w_tr_ofi_usu_aux,  @w_tr_usuario,     @w_tr_terminal,      @w_tr_fecha_ref,        @w_tr_secuencial_ref, @w_tr_estado,
      @w_tr_observacion,   @w_tr_gerente,      @w_tr_comprobante,  @w_tr_fecha_cont,  @w_tr_gar_admisible, @w_tr_reestructuracion, @w_tr_calificacion,   @w_tr_fecha_real
 
while @@fetch_status = 0
begin
 
   begin tran

   select
   @w_es_error        = 'N',
   @w_mensaje         = '',
   @w_tr_tran         = ltrim(rtrim(@w_tr_tran)),
   @w_tr_banco        = ltrim(rtrim(@w_tr_banco)),
   @w_tr_ofi_oper_aux = ltrim(rtrim(@w_tr_ofi_oper_aux)),
   @w_tr_ofi_usu_aux  = ltrim(rtrim(@w_tr_ofi_usu_aux)),
   @w_tr_toperacion   = ltrim(rtrim(@w_tr_toperacion))

   if @w_tr_tran = 'CAS' begin
      exec @w_error = sp_castigo_bm
      @i_banco         = @w_tr_banco,
      @i_secuencial    = @w_tr_secuencial,
      @i_fecha         = @i_fecha,
      @o_msg           = @w_mensaje out

      if @w_error <> 0 begin
         select 
         @w_es_error = 'S',
         @w_mensaje  = 'Error al Castigar Prestamo ('+ @w_tr_banco + ') ' + @w_mensaje
      end 
   end    
   
   ------------------------------------------------------------------------------
   /*VALIDA EN PRIMERA INSTANCIA LA EXISTENCIA DE LA OPERACION PARA TRANSACCION*/
   ------------------------------------------------------------------------------
   if not exists(select 1 from ca_operacion_bancamia where op_banco = @w_tr_banco)
   begin
       select @w_mensaje   = @w_mensaje  + ' No existe ptmo. ( '+ @w_tr_banco + '), '
       select @w_es_error  = 'S' -- FYA*
   end
 
   ---------------------------------------------------------------------------------------------------
   /*VALIDA QUE LA TRANSACCION REPORTADA NO EXISTA EN LA TABLA DEFINITIVA ca_transaccion_bancamia*/
   ---------------------------------------------------------------------------------------------------
    if exists (select 1 
    from   ca_transaccion_bancamia
    where  tr_secuencial = @w_tr_secuencial
    and    tr_banco      = @w_tr_banco)
    begin

       select @w_max_bm =  max(tr_secuencial)
       from   ca_transaccion_bancamia
       where  tr_banco      = @w_tr_banco

       select @w_max_tmp =  max(tr_secuencial)
       from   ca_transaccion_bancamia_tmp
       where  tr_banco      = @w_tr_banco

       if @w_max_bm < @w_max_tmp select @w_max_bm = @w_max_tmp
    
       update ca_transaccion_bancamia_tmp set 
       tr_secuencial       = @w_max_bm + 1
       where tr_banco      = @w_tr_banco
       and   tr_secuencial = @w_tr_secuencial
 
       update ca_det_trn_bancamia_tmp set 
       dtr_secuencial       = @w_max_bm + 1
       where dtr_banco      = @w_tr_banco
       and   dtr_secuencial = @w_tr_secuencial

       select @w_tr_secuencial = @w_max_bm + 1

    end

    ---------------------------------------------------------------------------------------------------
   /*VALIDA QUE LA TRANSACCION REPORTADA NO ESTE DUPLICADA EN ca_transaccion_bancamia_tmp     */
   ---------------------------------------------------------------------------------------------------
    select @w_count = 0

    select @w_count= count(1)-1 from cob_cartera..ca_transaccion_bancamia_tmp
    where tr_secuencial  = @w_tr_secuencial
    and    tr_banco      = @w_tr_banco

    if isnull(@w_count,0) > 0 begin

       set rowcount @w_count
 
       update ca_transaccion_bancamia_tmp   set 
       tr_operacion    = 999,
       tr_observacion  = 'Error Transaccion Duplicada'
       where tr_banco      = @w_tr_banco
       and   tr_secuencial = @w_tr_secuencial

       set rowcount 0

       truncate table #trn_dup

       insert into #trn_dup
       select distinct *
       from ca_det_trn_bancamia_tmp
       where dtr_banco      = @w_tr_banco
       and   dtr_secuencial = @w_tr_secuencial

       begin tran

       delete ca_det_trn_bancamia_tmp
       where dtr_banco      = @w_tr_banco
       and   dtr_secuencial = @w_tr_secuencial

       insert into ca_det_trn_bancamia_tmp
       select * from #trn_dup

       commit tran 


    end
 
    if @w_tr_secuencial is null or @w_tr_secuencial = 0
    begin
        select @w_mensaje = @w_mensaje + 'Error: Secuencial nulo o cero, '
        select @w_es_error  = 'S' -- FYA*
    end
 
    if @w_tr_fecha_mov is null or @w_tr_fecha_mov > @w_fecha_proceso
    begin
       select @w_mensaje = 'Fecha de transaccion mayor a la fecha de proceso'
       GOTO ERROR_1 
    end
 
    if @w_tr_toperacion <>'O_PAGOS'
    and not exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c
                   where t.tabla = 'ca_toperacion_bm'
                   and   c.tabla = t.codigo
                   and   c.codigo = @w_tr_toperacion)
    begin

        if exists (select 1 from ca_operacion_bancamia where op_banco  = @w_tr_banco and op_estado in (3,4)) begin
           select @w_tr_toperacion = 'CASTIGOS_M'
           update ca_transaccion_bancamia_tmp set
           tr_toperacion = @w_tr_toperacion
           where tr_banco = @w_tr_banco
               
        end else begin
           select @w_mensaje = @w_mensaje + 'No existe linea de credito (' + @w_tr_toperacion + '), '
           select @w_es_error  = 'S' -- FYA*
        end
    end
 

    if @w_tr_tran is null or @w_tr_tran not in ('DES','PAG','CAS')
    begin
        select @w_mensaje = @w_mensaje + 'Trans. no permitida (' + @w_tr_tran + '), '
        select @w_es_error  = 'S' -- FYA*
    end
     
    select @w_tr_observacion = 'CARGUE SISTEMA ANTERIOR'
 
    
 
    --*************************************************************************
    -------------------------------------------------------------
    ---  VALORES QUE SE CONSIDERA QUE NO DEBEN PARAR LA MIGRACION
    -------------------------------------------------------------
    --*************************************************************************
    if @w_tr_calificacion is null or @w_tr_calificacion not in ('A','B','C','D','E')
    begin
        select @w_mensaje = @w_mensaje + 'Error calificacion (' + @w_tr_calificacion + ') no existe, '
        select @w_tr_calificacion = 'A'
    end
 
    if @w_tr_gar_admisible is null or @w_tr_gar_admisible != 'N'
    begin
        select @w_mensaje = @w_mensaje + 'Error tipo de idoneidad de la garantia (, ' + @w_tr_gar_admisible + '), '
        select @w_tr_gar_admisible = 'N'        
    end


    if @w_tr_secuencial_ref is null or @w_tr_secuencial_ref != 0
    begin
        select @w_mensaje = @w_mensaje + 'Error en sec. de ref (' + cast(@w_tr_secuencial_ref as varchar) + '), '
        select @w_tr_secuencial_ref = 0
    end
 
    if @w_es_error  = 'S' GOTO ERROR_1 

    GOTO SIGUIENTE_1     
 
    ERROR_1:

    select @w_descripcion = isnull(@w_mensaje , 'ERROR_NO DEFINIDO')
 
    update ca_transaccion_bancamia_tmp   set 
    tr_operacion    = 999,
    tr_observacion  = substring(@w_descripcion,1,62)
    where tr_banco      = @w_tr_banco
    and   tr_secuencial = @w_tr_secuencial
 
    update ca_det_trn_bancamia_tmp set 
    dtr_dividendo    = 999
    where dtr_banco      = @w_tr_banco
    and   dtr_secuencial = @w_tr_secuencial

    exec sp_errorlog
    @i_fecha       = @w_fecha_proceso, 
    @i_error       = 7200, 
    @i_usuario     = 'car_bach',
    @i_tran        = 7000, 
    @i_tran_name   = @w_sp_name, 
    @i_rollback    = 'N',
    @i_cuenta      = @w_tr_banco,
    @i_descripcion = @w_mensaje
 
 
   SIGUIENTE_1:
   select 
   @w_contador = @w_contador + 1,
   @w_total    = @w_total    + 1
 
   if @w_contador = 500
   begin
      --select @w_total  
      commit tran 
      select @w_contador = 0
   end
 
   fetch cursor_transacciones
   into  @w_tr_secuencial,    @w_tr_fecha_mov,    @w_tr_toperacion,   @w_tr_moneda,      @w_tr_operacion,     @w_tr_tran,             @w_tr_en_linea,       @w_tr_banco,
         @w_tr_dias_calc,     @w_tr_ofi_oper_aux, @w_tr_ofi_usu_aux,  @w_tr_usuario,     @w_tr_terminal,      @w_tr_fecha_ref,        @w_tr_secuencial_ref, @w_tr_estado,
         @w_tr_observacion,   @w_tr_gerente,      @w_tr_comprobante,  @w_tr_fecha_cont,  @w_tr_gar_admisible, @w_tr_reestructuracion, @w_tr_calificacion,   @w_tr_fecha_real
 
end -- Fin cursor cursor_transacciones
 
close cursor_transacciones
deallocate cursor_transacciones
 
if @w_contador > 0
   commit tran
 

select 
@w_descripcion    = 'Transaccion migrada',
@w_tr_fecha_real  = getdate()


/* CONTROL TRANSACCIONES DE OFICINAS YA MIGRADAS EN COBIS CARTERA */

select distinct op_oficina
into #oficinas_cartera
from cob_cartera..ca_operacion

select banco=tr_banco, secuencial=tr_secuencial
into #trn_en_cobis
from ca_transaccion_bancamia_tmp, #dato_operacion, #oficinas_cartera
where do_banco         = tr_banco    
and   do_oficina       = op_oficina

update ca_transaccion_bancamia_tmp   set 
tr_operacion    = 999,
tr_observacion  = 'Transaccion de una Oficina YA Migrada en Cobis Cartera'
from #trn_en_cobis
where tr_banco         = banco    
and   tr_secuencial    = secuencial

update ca_det_trn_bancamia_tmp set 
dtr_dividendo    = 999
from #trn_en_cobis
where dtr_banco         = banco    
and   dtr_secuencial    = secuencial

insert into ca_errorlog (
er_fecha_proc,   er_error,   er_usuario,
er_tran,         er_cuenta,  er_descripcion,
er_anexo)
select 
@i_fecha,        7200,       'crebatch',
7000,            banco,      'ERR: TRANSACCION EN OFICINAS YA MIGRADAS EN COBIS CARTERA',
''
from #trn_en_cobis

begin tran

insert into ca_transaccion_bancamia_2
select 
tr_secuencial,    tr_fecha_mov,   tr_toperacion,    0,      tr_operacion,     tr_tran,             tr_en_linea,       tr_banco,
0,     

ofi_oper = isnull((select ho_entero
              from ca_homologar
             where ho_tabla      = 'oficinas'
               and ho_codigo_org = tr_ofi_oper
               and ho_tipo       = 'E'),tr_ofi_oper),

ofi_usu = isnull((select ho_entero
               from ca_homologar
               where ho_tabla      = 'oficinas'
               and   ho_codigo_org = tr_ofi_usu
               and   ho_tipo       = 'E'),tr_ofi_usu),      
tr_usuario,     tr_terminal,      tr_fecha_ref,        tr_secuencial_ref, 'ING',
@w_descripcion,   tr_gerente,          0,   '01/01/1900',  
tr_gar_admisible, 'N', tr_calificacion,  @w_tr_fecha_real, 
op_sector,        op_clase,              op_estado,
op_ente
from ca_transaccion_bancamia_tmp, ca_operacion_bancamia
where tr_operacion != 999
and   tr_banco      = op_banco

if @@error != 0 begin
  select @w_descripcion = 'Error en insercion ca_transaccion_bancamia_2'
  goto ERRORFIN
end 

update ca_transaccion_bancamia_2 set 
tr_ofi_oper = do_oficina
from #dato_operacion 
where do_banco         = tr_banco
and   tr_fecha_real    = @w_tr_fecha_real

if @@error != 0 begin
  select @w_descripcion = 'Error en update ca_transaccion_bancamia_2'
  goto ERRORFIN
end

insert into ca_det_trn_bancamia_2
select 
dtr_secuencial,                  dtr_banco,               dtr_dividendo,  
substring(dtr_concepto,1,10),    dtr_estado,              dtr_periodo, 
dtr_codvalor,                    dtr_monto,               dtr_monto_mn,   
dtr_moneda,                      dtr_cotizacion,          dtr_tcotizacion, 
dtr_afectacion,                  isnull(dtr_cuenta,''),   isnull(dtr_beneficiario, ''),
dtr_monto_cont
from ca_det_trn_bancamia_tmp
where dtr_dividendo != 999

if @@error != 0 begin
  select @w_descripcion = 'Error en insercion ca_det_trn_bancamia_2'
  goto ERRORFIN
end


select 
ttran      = tr_tran, 
banco      = dtr_banco, 
secuencial = dtr_secuencial, 
diferencia = sum(case dtr_afectacion when 'D' then dtr_monto else -1*dtr_monto end)
into #diferencias
from ca_det_trn_bancamia_2, ca_transaccion_bancamia_2
where tr_banco      = dtr_banco
and   tr_secuencial = dtr_secuencial
and   tr_tran      in ('DES','PAG')
and   tr_toperacion <> 'O_PAGOS'
group by tr_tran, dtr_banco, dtr_secuencial
having sum(case dtr_afectacion when 'D' then dtr_monto else -1*dtr_monto end) <> 0

insert into ca_det_trn_bancamia_2
select 
dtr_secuencial   = secuencial, 	
dtr_banco        = banco, 	 
dtr_dividendo    = 1, 
dtr_concepto     = case when abs(diferencia) <= @w_limite then @w_fp_ajmen else @w_fp_ajmay end,
dtr_estado       = 1,
dtr_periodo      = 0,
dtr_codvalor     = case when abs(diferencia) <= @w_limite then @w_cv_ajmen else @w_cv_ajmay end,
dtr_monto        = case when ttran = 'DES' then diferencia else diferencia * -1 end,
dtr_monto_mn     = case when ttran = 'DES' then diferencia else diferencia * -1 end,
dtr_moneda       = 0,
dtr_cotizacion   = 1,
dtr_tcotizacion  = 'C',
dtr_afectacion   = case when ttran = 'DES' then 'C' else 'D' end,
dtr_cuenta       = '',
dtr_beneficiario = 'AJUSTE POR DIFERENCIA (valida_tran_bancamia)',
dtr_monto_cont   = 0.00
from #diferencias
 
commit tran

  
begin tran
 
/* ELIMINAR DETALLE efemn DE LOS REGISTROS OTROS_PAGOS */
delete cob_cartera..ca_det_trn_bancamia_2
from cob_cartera..ca_transaccion_bancamia_2
where dtr_banco      = tr_banco     
and   dtr_secuencial = tr_secuencial 
and   dtr_banco      > ''
and   dtr_secuencial > 0
and   dtr_concepto   in ('EFEMN','CHLOCAL')
and   tr_toperacion  = 'O_PAGOS'

if @@error != 0 begin
  select @w_descripcion = 'Error al borrar registros tabla ca_det_trn_bancamia_2'
  goto ERRORFIN
end

 
commit tran
 
 
/* LOS CAPITALES CON AFECTACION CREDITO SON RENOVACIONES */
select @w_dtr_codvalor = cp_codvalor 
from cob_cartera..ca_producto_bancamia
where cp_producto = 'RENOVACION'
if @@rowcount = 0 select @w_dtr_codvalor = -99
 

begin tran
update cob_cartera..ca_det_trn_bancamia_2 set
dtr_concepto = 'RENOVACION',
dtr_codvalor = @w_dtr_codvalor
from cob_cartera..ca_transaccion_bancamia_2
where tr_banco       = dtr_banco
and   tr_secuencial  = dtr_secuencial
and   tr_tran        = 'DES'
and   dtr_concepto   = 'CAP'
and   dtr_afectacion = 'C'

if @@error != 0
begin
  select @w_descripcion = 'Error en update tabla ca_det_trn_bancamia_2 DES'
                                                         goto ERRORFIN
end

commit tran
 
/* EL IVAMIPYMES EN OTROS PAGOS SE LLAMARA IVAOPAGOS */
select @w_dtr_codvalor = co_codigo * 1000 + 10
from ca_concepto_bancamia
where co_concepto = 'IVAOPAGOS'
 
if @@rowcount = 0 select @w_dtr_codvalor = -99
 

begin tran
update cob_cartera..ca_det_trn_bancamia_2 set
dtr_concepto        = 'IVAOPAGOS',
dtr_codvalor        = @w_dtr_codvalor
from cob_cartera..ca_transaccion_bancamia_2
where tr_banco      = dtr_banco
and   tr_secuencial = dtr_secuencial
and   tr_toperacion = 'O_PAGOS'
and   dtr_concepto  = 'IVAMIPYMES'
if @@error != 0
begin
  select @w_descripcion = 'Error en update tabla ca_det_trn_bancamia_2 O_PAGOS'
  goto ERRORFIN
end
commit tran 


update ca_transaccion_bancamia_2 set 
tr_estado       = 'CON',
tr_comprobante  = -999,
tr_fecha_cont   = @w_fecha_proceso
from ca_det_trn_bancamia_2
where tr_banco = dtr_banco
and   tr_toperacion = 'O_PAGOS'
and   tr_secuencial  = dtr_secuencial
and   dtr_concepto   in ('VAREG','COA','VAR','CJM','TRAEG','FALTENCAJ','SOBRENCAJ',
                         'TRASENCAJ','CO_ERR','PADCA','PGCJME','PGCJME','PGCOMP',
                         'PGHONO','PGSERV','PADMOIN')

if @@error != 0
begin
  select @w_descripcion = 'Error al marcar como CONTABILIZADOS, otros pagos con conceptos VAREG,COA,VAR,CJM,...'
  goto ERRORFIN
end





while @@trancount > 0 commit tran 

return 0

ERRORFIN:
while @@trancount > 0 rollback


exec sp_errorlog
@i_fecha     = @w_fecha_proceso, 
@i_error     = @w_error, 
@i_usuario   = 'operador',
@i_tran      = 7000, 
@i_tran_name = 'sp_valida_transacciones_bancamia', 
@i_rollback  = 'N',
@i_cuenta    = 'VALIDACION TRN', 
@i_descripcion = @w_descripcion

return 999

go
 
