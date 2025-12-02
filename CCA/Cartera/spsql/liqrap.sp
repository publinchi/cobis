/*liqrap.sp *************************************************************/
/*      Archivo:            liqrap.sp                                   */
/*      Stored procedure:   sp_liquidacion_rapida                       */
/*      Base de datos:      cob_cartera                                 */
/*      Producto:           Cartera                                     */
/*      Disenado por:       Fernanda Lopez Ramos                        */
/*      Fecha de escritura: Mar/26/98                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/  
/*                       PROPOSITO                                      */
/*      Este programa efectua el desembolso y liquidacion de una        */
/*      operacion de Cartera.                                           */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*     FECHA        AUTOR                    RAZON                      */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_liquidacion_rapida')
   drop proc sp_liquidacion_rapida
go

create proc sp_liquidacion_rapida (
   @s_ssn               int          = null,
   @s_sesn              int          = null,
   @s_srv               varchar (30) = null,
   @s_lsrv              varchar (30) = null,
   @s_user              login        = null,
   @s_date              datetime     = null,
   @s_ofi               smallint     = null,
   @s_rol               tinyint      = null,
   @s_org               char(1)      = null,
   @s_term              varchar (30) = null,
   @i_banco             cuenta,    
   @i_producto          catalogo     = '',
   @i_cuenta            cuenta       = '',
   @i_beneficiario      descripcion  = '',
   @i_monto_op          money        = null,
   @i_moneda_op         tinyint      = null,
   @i_formato_fecha     int          = null,
   @i_externo           char(1)      = 'N',
   @i_afecta_credito    char(1)      = 'N',
   @i_cheque            int          = null,
   @i_renovacion        char(1)      = 'N',
   @i_crea_ext          char(1)      = null,
   @o_banco_generado    cuenta       = null out,
   @o_msg               varchar(255) = null out

) as
declare      
   @w_sp_name           varchar(30),
   @w_error             int,
   @w_return            int,
   @w_operacionca       int,
   @w_secuencial        int,
   @w_desembolso        int,
   @w_num_dec_mn        tinyint,
   @w_num_dec_op        tinyint,
   @w_op_monto          money,
   @w_total             money,
   @w_monto_op          money,
   @w_monto_des         money,
   @w_monto_mn          money,
   @w_anticipados       money,
   @w_dividendo         smallint,
   @w_int_ant           money,
   @w_ente_benef        int,
   @w_oficina           int,
   @w_nombre_tasa       varchar(10),
   @w_fecha             datetime,
   @w_tasa_int          float
/* VARIABLES INICIALES  */
select  @w_sp_name = 'sp_liquidacion_rapida'
select  @w_return  = 0

/* CABECERA */
select @w_operacionca = op_operacion,
       @w_oficina     = op_oficina
from ca_operacion
where op_banco = @i_banco


/* NUMERO SECUENCIAL DE DESEMBOLSO */
select @w_desembolso = 1

/*DIVIDENDO DEL ESTADO VIGENTE*/
select @w_dividendo = 1  /*LIQUIDADION EN PRIMER DIVIDENDO*/

begin tran

-- LA RENOVACION POR MASIVO CREA LOS REGISTROS DE DESEMBOLSO DE LA 
-- CANCELACION DEL TRAMITE ANTERIOR Y EL SOBRANDE QUE LE DESEMBOLSA AL CLIENTE.
if @i_crea_ext = 'S' begin 

   -- INGRESA LOS REGISTROS ADICIONALES DE LAS GARANTIAS EN TMP.
   exec @w_return          = sp_pasotmp -- sp_helptext sp_pasotmp
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @i_banco                = @i_banco,
   @i_operacionca          = 'S',
   @i_dividendo            = 'S',
   @i_amortizacion         = 'S',
   @i_cuota_adicional      = 'S',
   @i_rubro_op             = 'S',
   @i_nomina               = 'S'

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   delete ca_rubro_op_tmp where rot_operacion = @w_operacionca

   exec @w_return = sp_gen_rubtmp     -- sp_helpcode sp_gen_rubtmp
   @s_user              = @s_user,
   @s_date              = @s_date,
   @s_term              = @s_term,
   @s_ofi               = @w_oficina,
   @t_debug             = 'N',
   @i_crear_pasiva      = 'N',
   @i_operacionca       = @w_operacionca

   if @w_return <> 0 begin 
      if @@trancount > 0 rollback tran
      return @w_return
   end

   exec @w_return = sp_pasodef
        @i_banco           = @i_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   select @w_anticipados = sum(ro_valor)
   from ca_rubro_op
   where ro_operacion = @w_operacionca
   and   ro_fpago     = 'L'

   select @w_anticipados = isnull(@w_anticipados, 0)

   select @w_int_ant = sum(am_cuota)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion  = @w_operacionca
   and    am_dividendo  = 1
   and    ro_operacion  = @w_operacionca
   and    ro_concepto   = am_concepto
   and    ro_tipo_rubro = 'I'
   and    ro_fpago      = 'A'

   select @w_anticipados = @w_anticipados + isnull(@w_int_ant,0)
   select @w_monto_des = @i_monto_op - @w_anticipados

   /* DECIMALES DE LA MONEDA DE LA OPERACION Y NACIONAL */
   exec @w_return = sp_decimales
   @i_moneda       = @i_moneda_op,
   @o_decimales    = @w_num_dec_op out,
   @o_dec_nacional = @w_num_dec_mn out
   
   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return  -- Verificar numero de decimales asignados a esta moneda
   end

   /* VERIFICAR DECIMALES DE ENTRADA */
   if @i_monto_op <> round(@i_monto_op, @w_num_dec_op) begin
      if @@trancount > 0 rollback tran
      return 708193  -- Verificar numero de decimales asignados a esta moneda
   end

   /* CALCULAR MONTO OP Y MONTO MN */
   select @w_monto_mn = round(@w_monto_des, @w_num_dec_mn)
   select @w_monto_op = round(@w_monto_mn,@w_num_dec_op)

   exec @w_return = sp_borrar_tmp_int
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_sesn            = @s_sesn,
   @i_banco           = @o_banco_generado    

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   exec @w_return          = sp_pasotmp -- sp_helptext sp_pasotmp
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @i_banco                = @i_banco,
   @i_operacionca          = 'S',
   @i_dividendo            = 'S',
   @i_amortizacion         = 'S',
   @i_cuota_adicional      = 'S',
   @i_rubro_op             = 'S',
   @i_nomina               = 'S'

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   exec @w_return = cob_cartera..sp_qr_renovacion --   sp_helpcode sp_qr_renovacion 
   @s_ssn            = @s_ssn,  
   @s_date           = @s_date,  
   @s_user           = @s_user,  
   @s_term           = @s_term,      
   @s_ofi            = @s_ofi,  
   @s_lsrv           = @s_lsrv,  
   @s_srv            = @s_srv,  
   @i_banco          = @i_banco, 
   @i_formato_fecha  = 103,
   @i_crea_ext       = 'S',           -- 353 jtc 
   @o_msg_msv        = @o_msg   out   -- 353 jtc 

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   exec @w_return = sp_borrar_tmp_int
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_sesn            = @s_sesn,
   @i_banco           = @o_banco_generado    

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   exec @w_return          = sp_pasotmp -- sp_helptext sp_pasotmp
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @i_banco                = @i_banco,
   @i_operacionca          = 'S',
   @i_dividendo            = 'S',
   @i_amortizacion         = 'S',
   @i_cuota_adicional      = 'S',
   @i_rubro_op             = 'S',
   @i_nomina               = 'S'

   if @w_return <> 0 begin
      if @@trancount > 0 rollback tran
      return @w_return
   end

   select @w_monto_des = @w_monto_des - sum( dm_monto_mn) from ca_desembolso  where dm_operacion = @w_operacionca and dm_estado = 'NA'
   select @w_secuencial  = dm_secuencial from ca_desembolso  where dm_operacion = @w_operacionca and dm_estado = 'NA'

   select @w_monto_op = @w_monto_des
   select @w_monto_mn = @w_monto_des

   select @w_desembolso = 2
   select @w_ente_benef = op_cliente from cob_cartera..ca_operacion where op_banco = @i_banco

   if @w_monto_des > 0 begin 

      insert into ca_desembolso (
      dm_secuencial,      dm_operacion,      dm_desembolso,     dm_producto,        dm_cuenta,          dm_beneficiario, dm_oficina_chg,     
      dm_usuario,         dm_oficina,        dm_terminal,       dm_dividendo,       dm_moneda,          dm_monto_mds,    dm_monto_mop,    
      dm_monto_mn,        dm_cotizacion_mds, dm_cotizacion_mop, dm_tcotizacion_mds, dm_tcotizacion_mop, dm_estado,       dm_cheque,
      dm_fecha,           dm_ente_benef  )
      values(
      @w_secuencial,      @w_operacionca,    @w_desembolso,     @i_producto,        @i_cuenta,          @i_beneficiario, @s_ofi,             
      @s_user,            @s_ofi,            @s_term,           @w_dividendo,       @i_moneda_op,       @w_monto_des,    @w_monto_op,       
      @w_monto_mn,        1,                 1,                 'C',                'C',                'NA',            @i_cheque,
      @s_date,            @w_ente_benef  )
   end

   if @@error <> 0 begin 
      if @@trancount > 0 rollback tran
      return 710001
   end
end -- if @i_crea_ext = 'S'

exec @w_return     = sp_liquida 
@s_ssn             = @s_ssn,
@s_sesn            = @s_sesn,
@s_srv             = @s_srv,
@s_lsrv            = @s_lsrv,
@s_user            = @s_user,
@s_date            = @s_date,
@s_ofi             = @s_ofi,
@s_rol             = @s_rol,
@s_org             = @s_org,
@s_term            = @s_term,
@i_banco_ficticio  = @i_banco,
@i_banco_real      = @i_banco,
@i_fecha_liq       = @s_date,
@i_externo         = 'N',
@i_desde_cartera   = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
@i_afecta_credito  = @i_afecta_credito,
@i_renovacion      = @i_renovacion,
@i_crea_ext        = @i_crea_ext,
@o_banco_generado  = @o_banco_generado  out,
@o_msg             = @o_msg             out

if @w_return <> 0 begin
   if @@trancount > 0 rollback tran
   return @w_return
end

exec @w_return = sp_borrar_tmp_int
@s_user            = @s_user,
@s_term            = @s_term,
@s_sesn            = @s_sesn,
@i_banco           = @o_banco_generado    

if @w_return <> 0 begin
   if @@trancount > 0 rollback tran
   return @w_return
end

-- Control de Tasa Efectiva

if exists (select 1 from cob_cartera..ca_rubro_op
           where ro_operacion = @w_operacionca
           and   ro_tipo_rubro = 'I'
           and   ro_porcentaje_efa  = 0)
begin
   select @w_nombre_tasa = ro_referencial
   from cob_cartera..ca_rubro_op
   where ro_operacion = @w_operacionca
   and   ro_tipo_rubro = 'I'

   select @w_fecha = max(vr_fecha_vig)
   from   ca_valor_referencial
   where  vr_tipo = @w_nombre_tasa 
   and    vr_fecha_vig  <= @s_date
    
   select @w_tasa_int = vr_valor
   from   ca_valor_referencial
   where  vr_tipo = @w_nombre_tasa 
   and vr_secuencial = (select max(vr_secuencial)
                        from ca_valor_referencial
                        where vr_tipo = @w_nombre_tasa 
                        and   vr_fecha_vig  = @w_fecha)

   update cob_cartera..ca_rubro_op
   set ro_porcentaje_efa = @w_tasa_int ,
       ro_porcentaje_aux = @w_tasa_int 
   where ro_operacion = @w_operacionca
   and   ro_tipo_rubro = 'I'
   and   ro_porcentaje_efa = 0
end

commit tran


return @w_return 
go

