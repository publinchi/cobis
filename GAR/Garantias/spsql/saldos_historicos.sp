/*******************************************************************/
/* ARCHIVO:              saldos_historicos.sp                      */
/* Stored procedure:	 sp_saldos_historicos	          	       */
/* BASE DE DATOS:        cob_custodia 					           */
/* PRODUCTO:             GARANTIAS              	               */
/*******************************************************************/
/*                         IMPORTANTE                              */
/* Esta aplicacion es parte de los paquetes bancarios propiedad    */
/* de COBISCORP S.A.                                               */
/* Su uso no autorizado queda expresamente prohibido asi como      */
/* cualquier alteracion o agregado hecho por alguno de sus         */
/* usuarios sin el debido consentimiento por escrito de COBISCORP  */
/* Este programa esta protegido por la ley de derechos de autor    */
/* y por las  convenciones  internacionales de  propiedad inte-    */
/* lectual.  Su uso no  autorizado dara  derecho a  COBISCORP para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir    */
/* penalmente a los autores de cualquier infraccion.               */
/*******************************************************************/
/*                         PROPOSITO                               */
/* Lectura diaria de saldos de garantias y almacenamiento en       */
/* tablas correspondientes.                                        */
/*******************************************************************/
/*                      MODIFICACIONES                             */
/* FECHA           AUTOR             RAZON                         */
/* 24/Mar/2022     Juan C. Guzman  	 Emision Inicial               */
/* 25/Abr/2022     Juan C. Guzman    Cambio en subconsulta de ente */
/*******************************************************************/

use cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_saldos_historicos')
   drop proc sp_saldos_historicos
go


create proc sp_saldos_historicos
(
   @s_culture   varchar(10)   = 'NEUTRAL',
   @i_param1    int,          -- EMPRESA
   @i_param2    datetime      -- FECHA PROCESO
)
as

declare @w_sarta       int,
        @w_batch       int,
        @w_retorno_ej  int,
        @w_error       int,
        @w_msg         varchar(150)

-- CULTURA
exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out
   
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%sp_saldos_historicos%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'



delete from cob_externos..ex_dato_custodia
where dc_fecha = @i_param2

if @@error <> 0
begin 
   select @w_error = 1909034

   goto ERROR
end


delete from cob_conta_super..sb_dato_custodia
where dc_fecha = @i_param2

if @@error <> 0
begin 
   select @w_error = 1909035

   goto ERROR
end



insert into cob_externos..ex_dato_custodia
       (dc_fecha,                    dc_aplicativo,         dc_abierta,
        dc_tipo,                     dc_categoria,          dc_idonea,
        dc_oficina,                  dc_garantia,           dc_fecha_avaluo,
        dc_estado,                   dc_moneda,             dc_valor_avaluo, 
        dc_valor_actual,
        dc_cliente)
select  @i_param2,                   19,                    isnull(cu_abierta_cerrada, 'A'),
        cu_tipo,                     'N',                   isnull(cu_suficiencia_legal, 'O'),
        isnull(cu_oficina, 1),       cu_codigo_externo,     isnull(cu_fecha_avaluo, '01/01/1900'),
        isnull(cu_estado, 'P'),      isnull(cu_moneda, 0),  isnull(cu_valor_avaluo, 0),
        isnull(cu_valor_actual, 0), 
        (select top 1 cg_ente from cob_custodia..cu_cliente_garantia where cu_codigo_externo = cg_codigo_externo and cg_principal = 'S')		
from cu_custodia
where cu_filial = @i_param1

if @@error <> 0
begin 
   select @w_error = 1909036

   goto ERROR
end


insert into cob_conta_super..sb_dato_custodia
       (dc_fecha,                    dc_aplicativo,         dc_abierta,
        dc_tipo,                     dc_categoria,          dc_idonea,
        dc_oficina,                  dc_garantia,           dc_fecha_avaluo,
        dc_estado,                   dc_moneda,             dc_valor_avaluo, 
        dc_valor_actual,
        dc_cliente)
select  @i_param2,                   19,                    isnull(cu_abierta_cerrada, 'A'),
        cu_tipo,                     'N',                   isnull(cu_suficiencia_legal, 'O'),
        isnull(cu_oficina, 1),       cu_codigo_externo,     isnull(cu_fecha_avaluo, '01/01/1900'),
        isnull(cu_estado, 'P'),      isnull(cu_moneda, 0),  isnull(cu_valor_avaluo, 0),
        isnull(cu_valor_actual, 0), 
        (select top 1 cg_ente from cob_custodia..cu_cliente_garantia where cu_codigo_externo = cg_codigo_externo and cg_principal = 'S')
from cu_custodia
where cu_filial = @i_param1

if @@error <> 0
begin 
   select @w_error = 1909037

   goto ERROR
end

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

   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
