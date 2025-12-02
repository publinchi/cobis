/************************************************************************/
/*  Archivo:                aju_fuente_rec.sp                           */
/*  Stored procedure:       sp_aju_fuente_rec                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_aju_fuente_rec' and type = 'P')
   drop proc sp_aju_fuente_rec
go



create proc sp_aju_fuente_rec
as

declare
@w_error                int,
@w_msg                  varchar(255),
@w_fecha                datetime,
@w_est_novigente        tinyint,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_cancelado        tinyint,
@w_est_anulado          tinyint,
@w_est_credito          tinyint,
@w_codigo_fuente        int,
@w_fuente               varchar(10),
@w_monto                money,
@w_saldo                money,
@w_utilizado            money,
@w_tipo_fuente          varchar(10),
@w_porcentaje           float,
@w_porcentaje_otorgado  float,
@w_reservado            money,
@w_saldo_cca            money,
@w_reservado_cre        money,
@w_mov_utilizado        money,
@w_mov_reservado        money,
@w_valor_uti            money,
@w_valor_res            money,
@w_ajuste               char(1)

select @w_fecha = fp_fecha
from   cobis..ba_fecha_proceso

/* ESTADOS DE CARTERA */
exec @w_error = cob_cartera..sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 goto ERROR

create table #operaciones (banco cuenta)
create index idx1 on #operaciones (banco)

select
mf_fuente     = mf_fuente,
mf_utilizado  = sum(mf_valor_inc),
mf_reservado  = sum(mf_valor_res)
into  #movimientos
from  cr_mov_fuente_recurso
where mf_procesado = 'N'
group by  mf_fuente

declare cur_fuente_recurso cursor for select
fr_codigo_fuente,       fr_fuente,               fr_monto,
fr_saldo,               isnull(fr_utilizado, 0), fr_tipo_fuente,
fr_porcentaje,          fr_porcentaje_otorgado,  isnull(fr_reservado, 0)
from  cr_fuente_recurso
where fr_estado = 'V'
and   fr_monto  > 0

open  cur_fuente_recurso

fetch cur_fuente_recurso into
@w_codigo_fuente,       @w_fuente,              @w_monto,
@w_saldo,               @w_utilizado,           @w_tipo_fuente,
@w_porcentaje,          @w_porcentaje_otorgado, @w_reservado


while @@fetch_status = 0 begin

   if @@fetch_status = -1 begin
      select @w_msg   = 'ERROR EN EL CURSOR'
      goto ERROR
   end

   select
   @w_ajuste        = 'N',
   @w_mov_utilizado = 0,
   @w_mov_reservado = 0,
   @w_reservado_cre = 0,
   @w_saldo_cca     = 0

   /* SI LA FUENTE ES ROTATIVA SUMO EL SALDO CAPITAL, DE LO CONTRARIO EL MONTO ORIGINAL */
   if @w_tipo_fuente = 'R'  begin
      truncate table #operaciones

      insert into #operaciones
      select op_banco
      from   cob_cartera..ca_operacion, cr_tramite
      where  op_estado    not in (@w_est_credito, @w_est_novigente, @w_est_anulado, @w_est_cancelado)
      and    op_tramite        = tr_tramite
      and    tr_fuente_recurso = @w_fuente

      select
      @w_saldo_cca = sum(do_saldo_cap)
      from  cob_conta_super..sb_dato_operacion, #operaciones
      where do_banco      = banco
      and   do_aplicativo = 7
      and   do_fecha      = @w_fecha

   end else begin
      select @w_saldo_cca = sum(op_monto)
      from   cob_cartera..ca_operacion, cr_tramite
      where  op_estado    not in (@w_est_credito, @w_est_novigente, @w_est_anulado)
      and    op_tramite        = tr_tramite
      and    op_migrada       is null
      and    tr_fuente_recurso = @w_fuente
   end

   select @w_saldo_cca     = isnull(@w_saldo_cca,     0)

   /* SE OBTIENEN LOS MOVIMIENTOS QUE TODAVIA NO HAN AFECTADO LAS FUENTES DE RECURSO */
   select
   @w_mov_utilizado = mf_utilizado,
   @w_mov_reservado = mf_reservado
   from   #movimientos
   where  mf_fuente = @w_fuente

   select
   @w_mov_utilizado = isnull(@w_mov_utilizado, 0),
   @w_mov_reservado = isnull(@w_mov_reservado, 0)

   if @w_saldo_cca <> @w_utilizado + @w_mov_utilizado begin
      select
      @w_ajuste = 'S',
      @w_msg       = 'SALDO CARTERA NO COINCIDE CON UTILIZADO FUENTE RECURSOS '+@w_fuente + ' ('+convert(varchar, @w_saldo_cca, 1)+' <> '+convert(varchar, @w_utilizado + @w_mov_utilizado, 1)+' )'

      print 'ERROR:' + @w_msg

      exec sp_errorlog
      @i_fecha       = @w_fecha,
      @i_error       = 1,
      @i_usuario     = 'batch',
      @i_tran        = 21220,
      @i_tran_name   = 'sp_aju_fuente_rec',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg
   end

   select @w_reservado_cre = sum(tr_monto)
   from   cob_credito..cr_tramite, cob_cartera..ca_operacion
   where  tr_estado         = 'A'
   and    tr_tramite        = op_tramite
   and    op_estado        in (@w_est_novigente)
   and    tr_fuente_recurso = @w_fuente
   and    op_migrada       is null

   select @w_reservado_cre = isnull(@w_reservado_cre, 0)

   if @w_reservado_cre <> @w_reservado + @w_mov_reservado begin
      select
      @w_ajuste = 'S',
      @w_msg       = 'RESERVADO CRE. NO COINCIDE CON RESERVADO FUENTE RECURSOS '+@w_fuente + ' ('+convert(varchar, @w_reservado_cre, 1)+' <> '+convert(varchar, @w_reservado + @w_mov_reservado, 1)+' )'
      
      print 'ERROR:' + @w_msg

      exec sp_errorlog
      @i_fecha       = @w_fecha,
      @i_error       = 1,
      @i_usuario     = 'batch',
      @i_tran        = 21220,
      @i_tran_name   = 'sp_aju_fuente_rec',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg

   end

   /* SE ACTUALIZAN LOS SALDOS DE ACUERDO AL SALDO REAL */
   begin tran

   update cr_fuente_recurso set
   fr_saldo               = fr_monto - @w_saldo_cca - @w_reservado_cre,
   fr_utilizado           = @w_saldo_cca,
   fr_reservado           = @w_reservado_cre,
   fr_porcentaje_otorgado = (@w_saldo_cca * 100)/fr_monto
   where fr_codigo_fuente = @w_codigo_fuente

   if @@error <> 0 begin
      rollback tran
      select @w_msg = 'ERROR EN ACTUALIZACION DE FUENTE DE RECURSO '+ @w_fuente + '. '
      close cur_fuente_recurso
      deallocate cur_fuente_recurso
      goto ERROR
   end

   /* SE MARCAN LOS REGISTROS COMO PROCESADOS */
   update cr_mov_fuente_recurso set
   mf_procesado = 'S'
   where mf_fuente   = @w_fuente
   and   mf_procesado = 'N'

   if @@error <> 0 begin
      rollback tran
      select @w_msg = 'ERROR EN MARCADO DE PROCESADOS'
      close cur_fuente_recurso
      deallocate cur_fuente_recurso
      goto ERROR
   end

   if @w_ajuste = 'S'  begin

      select
      @w_valor_uti = @w_saldo_cca - (@w_utilizado + @w_mov_utilizado),
      @w_valor_res = @w_reservado_cre - (@w_reservado + @w_mov_reservado)

      /* SE INSERTA EL MOVIMIENTO DE AJUSTE */
      insert into cr_mov_fuente_recurso(
      mf_fecha,      mf_hora,           mf_user,
      mf_saldo_ini,  mf_fuente,         mf_banco,
      mf_tramite,    mf_valor_inc,      mf_valor_res,
      mf_saldo_fin,  mf_procesado)
      values(
      @w_fecha,      getdate(),         'batch',
      0,             @w_fuente,         'AJUSTE',
      0,             @w_valor_uti,      @w_valor_res,
      0,             'S')

      if @@error <> 0 begin
         rollback tran
         select @w_msg = 'ERROR EN INSERCION DETALLE DE AJUSTE'
         close cur_fuente_recurso
         deallocate cur_fuente_recurso
         goto ERROR
      end

   end
   commit tran

   SIGUIENTE:
   fetch cur_fuente_recurso into
   @w_codigo_fuente,       @w_fuente,              @w_monto,
   @w_saldo,               @w_utilizado,           @w_tipo_fuente,
   @w_porcentaje,          @w_porcentaje_otorgado, @w_reservado

end -- CUR_FUENTE_RECURSO

close cur_fuente_recurso
deallocate cur_fuente_recurso

/* ACTUALIZACION DE HISTORICO DE SALDOS */
delete cr_fuente_recurso_his
where  fr_fecha = @w_fecha

if @@error <> 0 begin
   select @w_msg = 'ERROR AL BORRAR cr_fuente_recurso_his'
   goto ERROR
end

insert into cr_fuente_recurso_his
select @w_fecha, *
from   cr_fuente_recurso

if @@error <> 0 begin
   select @w_msg = 'ERROR AL INSERTAR cr_fuente_recurso_his'
   goto ERROR
end

truncate table cr_tramites_contingencias

insert into cr_tramites_contingencias(
tc_tramite,        tc_monto,          tc_fuente,         
tc_estado,         tc_fecha_apr,      tc_oficina,
tc_estado_op,      tc_monto_op  )     
select             
tr_tramite,        tr_monto,          tr_fuente_recurso, 
tr_estado,         tr_fecha_apr,      tr_oficina,
op_estado,         op_monto           
from   cob_credito..cr_tramite, cob_cartera..ca_operacion
where  tr_estado         = 'A'
and    tr_tramite        = op_tramite
and    op_estado        in (@w_est_novigente)
and    op_migrada       is null

if @@error <> 0 begin
   select @w_msg = 'ERROR AL INSERTAR cr_tramites_contingencias'
   goto ERROR
end


return 0

ERROR:
   insert into cr_fuente_recurso_his
   select @w_fecha, *
   from   cr_fuente_recurso

   print 'ERROR:' + @w_msg

   exec sp_errorlog
   @i_fecha       = @w_fecha,
   @i_error       = 1,
   @i_usuario     = 'batch',
   @i_tran        = 21220,
   @i_tran_name   = 'sp_aju_fuente_rec',
   @i_rollback    = 'N',
   @i_descripcion = @w_msg

   return 1

GO
