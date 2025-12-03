/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Luis Carlos Moreno                      */
/*      Fecha de escritura:     Septiembre 2012                         */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* Actualizar el estado de la orden de caja asociada a un pago aplicado */
/* desde cuenta inactiva a 'E' y reestaurar el estado de cobranza de las*/
/* operaciones asociadas.                                               */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  24-09-12  L.Moreno          Emisión Inicial - Req: 341              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_act_paginac') 
drop proc sp_act_paginac
go

create proc sp_act_paginac
@i_param1    datetime
as 

declare @w_fecha_pro            datetime,
        @w_fecha                datetime,
        @w_fp_paginac           varchar(30),
        @w_cliente              int,
        @w_ctabanco             cuenta,
        @w_banco                cuenta,
        @w_est_cob              catalogo,
        @w_estado               char(3),
        @w_descripcion          varchar(60),
        @w_procesada            char(1),
        @w_error                int,
        @w_anexo                varchar(255),
        @w_descr_trn            varchar(60),
        @w_sec_ing              int,
        @w_cod_error            int,
        @w_cuenta               int,
        @w_msg                  varchar(100),
        @w_sp_name              varchar(32),
        @w_sp_name_batch        varchar(50),
        @w_s_app                varchar(30),
        @w_path                 varchar(255),
		@w_col_id               int,
		@w_columna              varchar(50),
		@w_cabecera             varchar(1000),
		@w_comando              varchar(1000),
		@w_nombre_plano         varchar(200),
        @w_nombre               varchar(255),
        @w_nombre_cab           varchar(255),
        @w_nom_tabla            varchar(100),
        @w_destino              varchar(2500),
        @w_errores              varchar(1500)
     
select @w_sp_name   = 'sp_act_paginac'

select @w_fecha = @i_param1

if @w_fecha is null
begin
  select @w_error = 2101084, @w_msg = 'Error, no se encuentra la fecha de ejecucion'
  goto ERROR2
end

-- OBTIENE FECHA DE PROCESO
select @w_fecha_pro = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_error = 722508, @w_msg = 'Error al leer fecha de proceso de cartera'
   goto ERROR2
end

-- CONSULTAR FORMA DE PAGO (PAGINAC)
select @w_fp_paginac = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and pa_nemonico = 'PAGINA'

if @@rowcount = 0
begin
   select @w_error = 722508, @w_msg = 'Error al leer forma de pago para Cuentas Inactivas Parametro general: PAGINAC'
   goto ERROR2
end

select @w_ctabanco = '',
       @w_error = 0

while 1 = 1 begin
   set rowcount 1
   select @w_error = 0,
          @w_cod_error = 0

   select 
   @w_cliente     = pi_cliente,
   @w_banco       = pi_banco,
   @w_est_cob     = pi_est_cob,
   @w_estado      = ab_estado,
   @w_sec_ing     = ab_secuencial_ing,
   @w_cuenta      = pi_cuenta,
   @w_ctabanco    = pi_ctabanco
   from
   ca_paginac with (nolock),
   ca_abono with (nolock),
   ca_abono_det with (nolock)
   where pi_ctabanco  > @w_ctabanco
   and   pi_fecha     = @w_fecha
   and   ab_operacion = pi_operacion
   and   ab_secuencial_ing = pi_sec_ing
   and   abd_operacion = ab_operacion
   and   abd_secuencial_ing = ab_secuencial_ing
   and   abd_concepto = @w_fp_paginac
   and   pi_estado = 'I'--Ingresado
   order by pi_ctabanco

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0

   begin tran

   if @w_estado = 'A'
   begin
      select @w_descr_trn = '',
             @w_procesada   = 'A'
      /* ANULA LA ORDEN DE PAGO DEL BRANCH */
      exec @w_error   = cob_interface..sp_act_est_branch
           @s_user    = 'op_batch',
           @s_date    = @w_fecha_pro,
           @i_cliente = @w_cliente,
           @i_cuenta  = @w_cuenta,
           @i_accion  = 'P',
           @i_descripcion = 'ANULACION POR PAGO CUENTAS INACTIVAS'
      if @w_error <> 0 goto ERROR

   end

   else
   begin

      /* BUSCA DESCRIPCION DEL ERROR ASOCIADO A LA NO APLICACION DEL PAGO */
      select 
      @w_cod_error = er_error,
      @w_descr_trn = isnull(er_descripcion,'')
      from ca_errorlog with (nolock)
      where er_fecha_proc = @w_fecha_pro
      and   er_cuenta     = @w_banco
      and   er_tran       = @w_sec_ing

      select @w_descr_trn = isnull(@w_descr_trn,''),
             @w_procesada   = 'R'

      /* ELIMINA EL PAGO NO APLICADO */
      exec @w_error = sp_eliminar_pagos
           @s_user  = 'op_batch',
           @s_term    = 'batch',
           @i_banco = @w_banco,
           @i_operacion = 'D',
           @i_secuencial_ing = @w_sec_ing

      if @w_error <> 0 goto ERROR

   end
   
   /* RETORNA ESTADO DE COBRANZA */
   update ca_operacion
   set op_estado_cobranza = @w_est_cob
   where op_banco = @w_banco

   if @@error <> 0
      select @w_descripcion = 'Error al actualizar tabla de operaciones ' + cast(@w_banco as varchar)   

   /* ACTUALIZA ESTADO EN TABLA DE CUENTAS CANCELADAS CON EL RESULTADO DE LA EJECUCION */
   if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   begin
      update cob_ahorros..ah_ctas_cancelar
      set cc_procesado = @w_procesada,
          cc_mensaje   = isnull(cc_mensaje,'') + @w_descr_trn
      where cc_fecha     = @w_fecha
      and   cc_cliente   = @w_cliente
      and   cc_ctabanco  = @w_ctabanco
      and   cc_operacion = @w_banco
      and   cc_procesado = 'S'
      and   cc_exclusivo = 'C'

      if @@error <> 0
         select @w_descripcion = 'Error al actualizar tabla de cuentas canceladas ' + cast(@w_banco as varchar)   
   end
   
   /* ACTUALIZA ESTADO EN TABLA CA_PAGINA */
   update cob_cartera..ca_paginac
   set pi_estado     = @w_procesada,
       pi_error      = @w_cod_error,
       pi_desc_error = @w_descr_trn
   where pi_fecha    = @w_fecha
   and   pi_cliente  = @w_cliente
   and   pi_ctabanco = @w_ctabanco
   and   pi_banco    = @w_banco
   and   pi_sec_ing  = @w_sec_ing

   if @@error <> 0
      select @w_descripcion = 'Error al actualizar tabla ca_pagina ' + cast(@w_banco as varchar)   

   commit tran

   ERROR:
      if @@trancount > 0
         rollback
      if @w_error > 0
      begin
         if @w_descripcion = ''
            select @w_descripcion = mensaje
	        from cobis..cl_errores
		    where numero = @w_error  
		   
		 select @w_anexo =  'SP --> sp_act_paginac '

	     insert into ca_errorlog
		 (er_fecha_proc,         er_error,                   er_usuario,
		  er_tran,               er_cuenta,                  er_descripcion,
		  er_anexo)
		 values(@w_fecha_pro ,   @w_error,                   'sa',
		        7269,            @w_banco,                   @w_descripcion,
		        @w_anexo) 
      end
end

-- ACTUALIZA ESTADO DE COBRANZA A OPERACIONES FALTANTES
update ca_operacion
set op_estado_cobranza = pi_est_cob
from ca_paginac
where op_operacion = pi_operacion
and   op_estado_cobranza = 'NO'
and   pi_est_cob <> 'NO'

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
/* Obtiene el path donde se va a generar el informe : E:\vbatch\cartera\listados\ */
select @w_sp_name_batch = 'cob_cartera..sp_act_paginac'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = @w_sp_name_batch

if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
  goto ERROR2
end

/* Obtiene el parametro de la ubicacion del kernel\bin en el servidor */
select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM' and
      pa_nemonico = 'S_APP'
                                                                                                                                                                                                                                                       
if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
  goto ERROR2
end

select 
@w_nombre       = 'Pagos_Cartera_Inac',
@w_nom_tabla    = 'ah_ctas_cancelar',
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), ''),
@w_nombre_cab   = @w_nombre

select 
@w_nombre_plano = @w_path + @w_nombre_cab + '_' + convert(varchar(2), datepart(dd,getdate())) + '_' + convert(varchar(2), datepart(mm,getdate())) + '_' + convert(varchar(4), datepart(yyyy, getdate())) + '.txt'

select @w_cabecera = 'cc_fecha^|cc_zona^|cc_nom_zona^|cc_oficina^|cc_nom_oficina^|cc_ctabanco^|cc_cuenta^|cc_estado_cta^|cc_titularidad^|cc_cliente^|cc_nombre_cli^|cc_documento^|cc_producto^|cc_disponible^|cc_operacion^|cc_estadocca^|cc_desc_est^|cc_diasmora^|cc_castigado^|cc_valorven^|cc_deudatotal^|cc_saldado^|cc_exclusivo^|cc_procesado^|cc_fecha_aper^|cc_fecha_ult_mov^|cc_fecha_proc^|cc_mensaje^|cc_exento^|cc_sec'
print @w_nombre_plano
--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERROR2
end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_ahorros..ah_ctas_cancelar out '

select 
@w_destino  = @w_path + 'Pagos_Cartera_Inac.txt',
@w_errores  = @w_path + 'Pagos_Cartera_Inac.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando Archivo Cupos_Credito' 
end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'Pagos_Cartera_Inac.txt' + ' ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERROR2
end
                                                                                                                                                                                                             
return 0

ERROR2:

exec sp_errorlog 
@i_fecha       = @w_fecha_pro,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error

go

