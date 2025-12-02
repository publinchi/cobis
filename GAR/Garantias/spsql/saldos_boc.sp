/************************************************************************/
/*   NOMBRE LOGICO:        saldos_boc.sp                                */
/*   NOMBRE FISICO:        sp_saldos_boc                                */
/*   BASE DE DATOS:        cob_custodia                                 */
/*   PRODUCTO:             GARANTIAS                                    */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA:                                                */
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
/*                         PROPOSITO                                    */
/* Generar los saldos definitivos que contabilidad espera en las        */
/* estructuras del BOC.                                                 */
/************************************************************************/
/*                      MODIFICACIONES                                  */
/* FECHA           AUTOR             RAZON                              */
/* 30/Mar/2022     Juan C. Guzman  	 Emision Inicial                    */
/* 21/Abr/2022     Juan C. Guzman    Cambios en lectura de datos        */
/*                                   para tabla temporal                */
/* 05/Ago/2022     Juan C. Guzman    Cambio en filtro de tabla temp     */
/*                                   Para no agregar garantias          */
/*                                   estado 'P' y 'C' -> R191094        */
/* 07/Nov/2023	   M. Cordova		 Tambien no agregar garantias 		*/
/*									 eliminadas ('A')					*/
/************************************************************************/

use cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_saldos_boc')
   drop proc sp_saldos_boc
go

create proc sp_saldos_boc
(
   @s_culture   varchar(10)   = 'NEUTRAL',
   @i_param1    int,          -- EMPRESA
   @i_param2    datetime      -- FECHA PROCESO
)
as

declare @w_moneda_nac        tinyint,
        @w_area_contable     smallint,
        @w_max_fecha         datetime,
        @w_cotizacion        float,
        @w_error             int,
        @w_dct_moneda        tinyint,
        @w_dct_saldo         money,
        @w_dct_cta_contable  varchar(30),
        @w_ofi_conta         smallint,
        @w_saldo_mn          money,
        @w_saldo_me          money,
        @w_sarta             int,
        @w_batch             int,
        @w_retorno_ej        int,
        @w_msg               varchar(150),
        @w_err_cursor        char(1),
        @w_cod_dolar         tinyint,
        @w_prod_garantias    tinyint

select @w_err_cursor = 'N'

-- CULTURA
exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out
   
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%sp_saldos_boc%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'

-- Codigo producto Garantias
select @w_prod_garantias = pd_producto 
from  cobis..cl_producto 
where pd_abreviatura = 'GAR'

-- Moneda extranjera
select @w_cod_dolar = pa_tinyint 
from cobis..cl_parametro
where pa_nemonico = 'CDOLAR'
and   pa_producto = 'ADM'

-- Moneda nacional
select @w_moneda_nac = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

if @@rowcount = 0
begin
   --No existe parametro general para moneda nacional
   select @w_error = 1909038

   goto ERROR
end

--Area contable
select @w_area_contable = pa_smallint
from   cobis..cl_parametro
where  pa_nemonico = 'ARG'
and    pa_producto = 'GAR'

if @@rowcount = 0
begin
   --No existe el area contable para Garantia
   select @w_error = 1909020

   goto ERROR
end

select @w_max_fecha = max(ct_fecha)
from cob_conta..cb_cotizacion 
where ct_moneda = @w_cod_dolar

select @w_cotizacion = ct_valor
from cob_conta..cb_cotizacion 
where ct_moneda = @w_cod_dolar
and ct_fecha = @w_max_fecha

if @@rowcount = 0
begin
   select @w_cotizacion = 1 -- Para soportar instituciones que no manejan moneda extranjera.
   --No existe cotizacion para moneda extranjera
   --select @w_error = 1909039
   --goto ERROR
end


if exists (select 1 from sysobjects where name = '#dato_custodia')
   drop table #dato_custodia
  
create table #dato_custodia (
   dct_fecha            smalldatetime  not null,
   dct_aplicativo       tinyint        not null,
   dct_garantia         varchar(64)    not null,
   dct_oficina          smallint       not null,
   dct_cliente          int            null,
   dct_categoria        char(1)        not null,
   dct_tipo             varchar(14)    not null,
   dct_idonea           char(1)        not null,
   dct_fecha_avaluo     smalldatetime  not null,
   dct_moneda           tinyint        not null,
   dct_valor_avaluo     money          not null,
   dct_valor_actual     money          not null,
   dct_estado           char(1)        not null,
   dct_abierta          char(1)        not null,
   dct_cuenta_contable  varchar(30)    null
)

insert into #dato_custodia (
        dct_fecha,   dct_aplicativo, dct_garantia,
        dct_oficina, dct_cliente,    dct_valor_actual,
        dct_tipo,    dct_idonea,     dct_fecha_avaluo,
        dct_moneda,  dct_estado,     dct_valor_avaluo,
        dct_abierta, dct_categoria,  dct_cuenta_contable)

select  dc_fecha,    dc_aplicativo,  dc_garantia,
        dc_oficina,  dc_cliente,     dc_valor_actual,
        dc_tipo,     dc_idonea,      dc_fecha_avaluo,
        dc_moneda,   dc_estado,      dc_valor_avaluo,
        dc_abierta,  dc_categoria,   null
from cob_conta_super..sb_dato_custodia,
     cob_custodia..cu_tipo_custodia
where dc_fecha         = @i_param2
and   dc_tipo          = tc_tipo
and   dc_estado not in ('P','C', 'A')
and   tc_contabilizar  = 'S'

if @@error <> 0
begin
   --Error al insertar registros en tabla temporal
   select @w_error = 1909040

   goto ERROR
end


update #dato_custodia
set dct_cuenta_contable = re_substring
from cob_conta..cb_relparam
where re_parametro = 'GTC'
and   re_clave     = dct_tipo + '.' + convert(varchar,dct_moneda)
and   re_producto  = @w_prod_garantias

if @@error <> 0
begin
   --Error al actualizar campo de cuenta contable en tabla temporal
   select @w_error = 1909041

   goto ERROR
end

-- Eliminar registros de tabla cob_conta..cb_boc
exec @w_error = cob_conta..sp_ing_opera
   @i_operacion = 'D',
   @i_empresa   = @i_param1,
   @i_producto  = @w_prod_garantias,
   @i_fecha     = @i_param2
   
if @w_error != 0
begin
   goto ERROR
end


declare cursor_dato_custodia cursor for
select dct_moneda, dct_valor_actual, dct_cuenta_contable,
       re_ofconta
from #dato_custodia, 
     cob_conta..cb_relofi
where dct_oficina      = re_ofadmin
and   re_filial        = @i_param1
and   re_empresa       = @i_param1
and   dct_valor_actual <> 0

open cursor_dato_custodia    

fetch next from cursor_dato_custodia into
   @w_dct_moneda, @w_dct_saldo, @w_dct_cta_contable,
   @w_ofi_conta
   
while (@@fetch_status = 0)
begin
   if (@@fetch_status = -1)
   begin
      close cursor_dato_custodia    
      deallocate cursor_dato_custodia
		  
      -- Error en lectura de cursor                                                                                     
      select @w_error = 1909043

      goto ERROR
   end
   
   if @w_dct_moneda = @w_moneda_nac
   begin
      select @w_saldo_mn = @w_dct_saldo,
             @w_saldo_me = 0
   end
   else
   begin
      select @w_saldo_mn = @w_dct_saldo * @w_cotizacion,
             @w_saldo_me = @w_dct_saldo
   end
   
   exec @w_error = cob_conta..sp_ing_opera
      @i_operacion    = 'I',
      @i_empresa      = @i_param1,
      @i_oficina      = @w_ofi_conta,
      @i_area         = @w_area_contable,
      @i_cuenta       = @w_dct_cta_contable,
      @i_val_opera_mn = @w_saldo_mn,
      @i_val_opera_me = @w_saldo_me,
      @i_moneda       = @w_dct_moneda,
      @i_fecha        = @i_param2,
      @i_producto     = @w_prod_garantias
	  
   if @w_error != 0
   begin
      select @w_err_cursor = 'S'

      goto ERROR
   end
   
   NEXT_CURSOR:
      fetch next from cursor_dato_custodia into
      @w_dct_moneda, @w_dct_saldo, @w_dct_cta_contable,
      @w_ofi_conta

end

close cursor_dato_custodia    
deallocate cursor_dato_custodia

return 0

ERROR:
   select @w_msg = re_valor
   from cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int
      and re_cultura like '%'+@s_culture+'%')
   where numero = @w_error

   exec @w_retorno_ej = cobis..sp_ba_error_log
      @i_sarta   = @w_sarta,
      @i_batch   = @w_batch,
      @i_error   = @w_error,
      @i_detalle = @w_msg

   if @w_err_cursor = 'S'
   begin
      select @w_err_cursor = 'N'

      goto NEXT_CURSOR
   end 

   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
