/***********************************************************************/
/*  Archivo:                   ca_funrecur.sp                          */
/*  Stored procedure:          sp_fuen_recur                           */
/*  Base de Datos:             cob_credito                             */
/*  Producto:                  Credito                                 */
/*  Disenado por:              Jonnatan Peña                           */
/*  Fecha de Documentacion:    01/Abr/08                               */
/***********************************************************************/
/*                          IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "MACOSA",representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*          PROPOSITO                                                  */
/*  Este stored procedure permite realizar las siguientes              */
/*  operaciones: Insert, Update, Delete, Query, All, Value, Search     */
/*  en cr_califica_interna.                                            */
/*                                                                     */
/***********************************************************************/
/*          MODIFICACIONES                                             */
/*  FECHA       AUTOR               RAZON                              */
/*  01/Abr/08   Jonnatan Peña       Emision Inicial                    */
/*  24/Mar/09   S. Ramírez          Fuente de Recurso Bancoldex AECI   */
/***********************************************************************/


use cob_cartera
go


if exists (select * from sysobjects where name = 'sp_fuen_recur' and xtype = 'P')
    drop proc sp_fuen_recur
go

create proc sp_fuen_recur (
@s_ssn                INT          = null,
@s_date               datetime,
@s_user               login        = null,
@s_ofi                INT          = null,
@s_term               descripcion  = null,
@i_operacion          char(1)      = null,
@i_modo               smallint     = 0,
@i_fondo_id      int          = null,
@i_fondeador          varchar(10)  = null,
@i_monto              money        = null,
@i_saldo              money        = null,
@i_utilizado          money        = null,
@i_estado             varchar(10)  = null,
@i_tipo_fuente        char(1)      = 'R',
@i_toperacion         catalogo     = null,
@i_fecha_ini          datetime     = null,
@i_fecha_fin          datetime     = null,
@i_porcentaje         float        = null,
@i_secuencial         int          = null,
@i_nombre_fondo       varchar(100) = null,
@i_opcion             char(1)      = null,
@i_operacionca        int          = null,
@i_dividendo          int          = null,
@i_reverso            char(1)      = 'N',
@i_fecha_proc         datetime     = null,
@i_fecha_vig          datetime     = null
)
as
declare

@w_error              int,          /* VALOR QUE RETORNA  */
@w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
@w_fuente             varchar(10),
@w_monto              money,
@w_saldo              money,
@w_utilizado          money,
@w_estado             varchar(10),
@w_secuencial         int,
@w_fecha_proc         datetime,
@w_fondo_id           int,
@w_commit             char(1),
@w_monto_inc          MONEY,
@w_valor_utilizado    MONEY,
@w_fecha_proceso      DATETIME,
@w_fecha_vig          DATETIME,
@w_return             int,
@w_banco              cuenta


select @w_commit = 'N'

select @w_fecha_proc = fp_fecha
from cobis..ba_fecha_proceso

create table #fondos(
    id                   int,
    nombre               varchar(100),    
    fondeador_id         varchar(10),
    monto                money,   
	utilizado            money,   
    disponible           money,   --saldo
	fecha_vig            datetime null,
    estado               varchar(10)    
)

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @i_operacion = 'U' or @i_operacion = 'I'
begin

   if @i_fecha_vig < @w_fecha_proceso
   begin

       select @w_error = 724612 -- No se admite fecha de vigencia menor a la fecha de proceso
       goto ERROR
   end
   
end

-----------------------------
-- INSERCION DEL REGISTRO
-----------------------------
if @i_operacion = 'I'

/* NUMERO SECUENCIAL CORRESPONDIENTE */
begin

   exec cobis..sp_cseqnos 
      @i_tabla     = 'ca_fuente_recurso',
      @o_siguiente = @w_fondo_id out

   if @w_fondo_id is null
   begin
      select @w_error = 2101007
      goto ERROR
   end
   
   /*SECUENCIAL DE FONDO*/   
   exec @w_secuencial = sp_gen_sec
   @i_operacion       = -2
   
   
   if @@trancount = 0
   begin
      select @w_commit = 'S'
      begin tran
   end
   
   if exists (select 1 from ca_fuente_recurso where fr_nombre = @i_nombre_fondo)
   begin
      select @w_error = 724614 --Nombre de Fondo ya existe 
      goto ERROR
   end
   
   exec @w_return = cobis..sp_catalogo
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @t_trn         = 584,
   @i_operacion   = 'I',
   @i_tabla       = 'ca_categoria_linea',
   @i_codigo      = @w_fondo_id,
   @i_descripcion = @i_nombre_fondo,
   @i_estado      = 'V'
   
   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR
   end
   

   insert into ca_fuente_recurso(
   fr_fondo_id,              fr_nombre,              fr_fuente,
   fr_monto,                 fr_saldo,               fr_utilizado,
   fr_fecha_vig,             fr_estado,              fr_tipo_fuente,  
   fr_porcentaje,            fr_porcentaje_otorgado, fr_reservado)
   values (
   @w_fondo_id,          @i_nombre_fondo,      @i_fondeador,
   @i_monto,             @i_monto,          0,
   @i_fecha_vig,         'V',               @i_tipo_fuente,
   0,                     0,                0)
   
   if @@error <> 0
   begin
      select @w_error = 2103001
      goto ERROR
   end

   
   insert into ca_transaccion(
   tr_fecha_mov,          tr_toperacion,        tr_moneda,
   tr_operacion,          tr_tran,              tr_secuencial,
   tr_en_linea,           tr_banco,             tr_dias_calc,
   tr_ofi_oper,           tr_ofi_usu,           tr_usuario,
   tr_terminal,           tr_fecha_ref,         tr_secuencial_ref,
   tr_estado,             tr_gerente,           tr_gar_admisible,
   tr_reestructuracion,   tr_calificacion,      tr_observacion,                              
   tr_fecha_cont,         tr_comprobante)
   values(
   @s_date,               'GRUPAL',              0,
   -2,                    'FND',              @w_secuencial, 
   'S',                   'FONDO',              0,
   @s_ofi,                @s_ofi,               @s_user,
   @s_term,               @s_date,              -999,  
   'ING',                 0,                   '',
   '',                    '',                   'CREACION DE FONDO',
   @s_date,               0)
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
   
					 
   insert into ca_det_trn(
   dtr_secuencial,     dtr_operacion, dtr_dividendo,
   dtr_concepto,       dtr_estado,    dtr_periodo,
   dtr_codvalor,       dtr_monto,     dtr_monto_mn,
   dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
   dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
   dtr_monto_cont)
   values(
   @w_secuencial,     -2,              0,
   'CAP',             1,               0,
   10010,             @i_monto,        @i_monto,
   0,                 1,               'N',
   'D',              '00000',          'CARTERA',
   0.00)
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
   
   if @w_commit = 'S'
   begin
      select @w_commit = 'N'
      commit tran
   end
  
end
-----------------------------
-- MODIFICACION DEL REGISTRO
-----------------------------
if @i_operacion = 'U'
begin
   
   select @w_monto_inc = @i_monto - fr_monto
   from ca_fuente_recurso
   where fr_fondo_id = @i_fondo_id
   
   if @@rowcount = 0
   begin
      select @w_error = 2105002
      goto ERROR
   end
   
   
   select
   @w_valor_utilizado = isnull(sum(fm_monto),0)
   from ca_fuente_recurso_mov
   where fm_fondo_id= @i_fondo_id

   if @i_monto < @w_valor_utilizado  
   begin
      select @w_error = 724610 --Monto nuevo del fondo debe ser mayor o igual al monto utilizado del fondo
      goto ERROR
   end
   
   
   /*SECUENCIAL DE FONDO*/   
   exec @w_secuencial = sp_gen_sec
   @i_operacion       = -2
   
   if @@trancount = 0
   begin
      select @w_commit = 'S'
      begin tran
   end
   
   update ca_fuente_recurso set
   fr_nombre     = @i_nombre_fondo,
   fr_monto      = @i_monto,
   fr_estado     = @i_estado,
   fr_fecha_vig  = @i_fecha_vig
   where fr_fondo_id = @i_fondo_id
   
   if @@error <> 0
   begin
      select @w_error = 2105001
      goto ERROR
   end
   
   insert into ca_transaccion(
   tr_fecha_mov,          tr_toperacion,        tr_moneda,
   tr_operacion,          tr_tran,              tr_secuencial,
   tr_en_linea,           tr_banco,             tr_dias_calc,
   tr_ofi_oper,           tr_ofi_usu,           tr_usuario,
   tr_terminal,           tr_fecha_ref,         tr_secuencial_ref,
   tr_estado,             tr_gerente,           tr_gar_admisible,
   tr_reestructuracion,   tr_calificacion,      tr_observacion,                              
   tr_fecha_cont,         tr_comprobante)
   values(
   @s_date,               'GRUPAL',              0,
   -2,                    'FND',              @w_secuencial, 
   'S',                   'FONDO',              0,
   @s_ofi,                @s_ofi,               @s_user,
   @s_term,               @s_date,              -999,  
   'ING',                 0,                   '',
   '',                    '',                   'ACTUALIZACION DE FONDO',
   @s_date,               0)
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
   
					 
   insert into ca_det_trn(
   dtr_secuencial,     dtr_operacion, dtr_dividendo,
   dtr_concepto,       dtr_estado,    dtr_periodo,
   dtr_codvalor,       dtr_monto,     dtr_monto_mn,
   dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
   dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
   dtr_monto_cont)
   values(
   @w_secuencial,     -2,              0,
   'CAP',             1,               0,
   10010,             @w_monto_inc,    @w_monto_inc,
   0,                 1,               'N',
   'D',              '00000',          'CARTERA',
   0.00)
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
   
   if @w_commit = 'S'
   begin
      select @w_commit = 'N'
      commit tran
   end

end


-----------------------------
-- CONSULTA OPCION SEARCH
-----------------------------
if @i_operacion = 'S'
begin

   insert into #fondos
   select       
   id               = fr_fondo_id,
   nombre           = fr_nombre,
   fondeador_id     = fr_fuente,
   monto            = isnull(fr_monto, 0),
   utilizado        = fr_utilizado,
   disponible       = isnull(fr_saldo, 0),
   fecha_vig        = fr_fecha_vig,
   estado           = fr_estado
   from ca_fuente_recurso
   order by fr_fondo_id
  
   select 
   fondo_id = fm_fondo_id,
   fondo_utilizado = isnull(sum(fm_monto),0)
   into #saldos_utilizados
   from ca_fuente_recurso_mov
   group by fm_fondo_id
   
   update #fondos set 
   utilizado = fondo_utilizado
   from #saldos_utilizados
   where id = fondo_id
   
   if @i_modo = 0 select @i_fondo_id = 0
   
   set rowcount 20
   
   select
   'Fondo id'     =  id,
   'Nombre'       =  nombre,
   'Fondeador id' =  fondeador_id,
   'Monto'        =  monto,
   'Utilizado'    =  utilizado,
   'Disponible'   =  monto - utilizado,
   'Fecha Vig.'   =  fecha_vig,
   'Estado'       =  estado
   from #fondos
   where id > @i_fondo_id
   order by id
   
   set rowcount 0
   
end

if @i_operacion = 'F'
begin

   if @i_monto = 0 return 0
   
   select 
   @w_fondo_id = op_origen_fondos,
   @w_banco    = op_banco
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   if @@rowcount = 0
   begin
      select @w_error = 710201 -- No existe la operacion
      goto ERROR
   end 
   
   select 
   @w_saldo      = fr_monto,
   @w_fecha_vig  = fr_fecha_vig,
   @w_estado     = fr_estado
   from ca_fuente_recurso
   where fr_fondo_id = @w_fondo_id
   
   if @@rowcount = 0   return 0
   
   -- DESEMBOLSO Y NO ES REVERSO 
   if @i_opcion = 'D' and @i_reverso = 'N' 
   begin
      if @w_estado = 'B'
      begin
         select @w_error = 724616 -- Fondo se encuentra bloqueado
         goto ERROR
      end
      
	  if @i_fecha_proc > @w_fecha_vig
	  begin
	     select @w_error = 724613 --La fecha de proceso supera la fecha de vigencia del fondo
         goto ERROR
	  end
	  
	  
	  select
      @w_valor_utilizado = isnull(sum(fm_monto),0)
      from ca_fuente_recurso_mov
      where fm_fondo_id = @w_fondo_id

	  select @w_monto = @i_monto
	  
      if @w_monto > (@w_saldo - @w_valor_utilizado)
      begin
         select @w_error = 724611 --Monto de la transaccion supera el disponible del fondo
         goto ERROR
      end
   
   end
   
   -- PAGO Y NO ES REVERSO 
   if @i_opcion = 'P' and @i_reverso = 'N' select @w_monto = @i_monto * (-1)
   
   -- DESEMBOLSO Y ES REVERSO
   if @i_opcion = 'D' and @i_reverso = 'S' select @w_monto = @i_monto * (-1)
   
   -- PAGO Y ES REVERSO
   if @i_opcion = 'P' and @i_reverso = 'S' select @w_monto = @i_monto
   
   -- INSERTO EL MOVIMIENTO
   insert into ca_fuente_recurso_mov(
   fm_fondo_id,           fm_banco,      fm_operacion,
   fm_secuencial_trn,     fm_dividendo,  fm_fecha_mov,
   fm_fecha_val,          fm_hora,       fm_monto)
   values(
   @w_fondo_id,           @w_banco,      @i_operacionca,
   @i_secuencial,         @i_dividendo,  @s_date,
   @i_fecha_proc,         getdate(),     @w_monto)
   
   if @@error <> 0
   begin
      select @w_error = 710001 --Error en la insercion del registro
      goto ERROR
   end
   
end

return 0

ERROR:
if @w_commit = 'S'
begin
   select @w_commit = 'N'
   rollback tran
   return @w_error
end
else
begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return @w_error
end

go

