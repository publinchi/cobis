/************************************************************************/
/*     Archivo:                sp_divisas_credito.sp                    */
/*     Stored procedure:       sp_divisas_credito                       */
/*     Base de datos:          cob_credito                              */
/*     Producto: Clientes                                               */
/*     Disenado por:           Jose Mieles                              */
/*     Fecha de escritura:     01-Jul-2021                              */
/************************************************************************/
/*                             IMPORTANTE                               */
/*     Este programa es parte de los paquetes bancarios propiedad de    */
/*     COBISCORP.                                                       */
/*     Su uso no autorizado queda expresamente prohibido asi como       */
/*     cualquier alteracion o agregado hecho por alguno de sus          */
/*     usuarios sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de COBISCORP o su representante.           */
/************************************************************************/
/*                             PROPOSITO                                */
/*     Este programa procesa las transacciones del stored procedure     */
/*     Insercion de grupo                                               */
/*     Actualizacion de grupo                                           */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*     FECHA           AUTOR                RAZON                       */
/*     01-Jul-2021     Jose Mieles     Version Inicial                  */
/************************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_divisas_credito')
    drop proc sp_divisas_credito
go


create proc sp_divisas_credito (
       @s_date                  datetime    = null,       -- Fecha del sistema
       @s_user                  login       = null,       -- Usuario del sistema
       @s_ssn                   int         = null,       -- Secuencial unico COBIS
       @t_show_version          tinyint     = 0,          -- Versionamiento del SP
       @s_ofi                   smallint    = null,
       @t_trn                   int,
       @t_debug                 char(1)     = 'N',
       @t_file                  varchar(14) = null,
       @i_oficina               smallint    = null,        -- Oficina donde debe ser registrada la transaccion.  Afectará contablemente
       @i_modulo                char(3),                   -- Nemonico del modulo COBIS que origina la operacion de divisas
       @i_moneda_origen         tinyint     = null,         /* Moneda en la cual está expresado el monto a convertir                     */
       @i_operacion             char(1),
       @i_valor                 money       = 0,            /* Monto a convertir                                                         */
       @i_valor_destino         money       = 0,
       @i_moneda_destino        tinyint     = null,         /* Moneda en la cual se expresará el monto                                   */
       @i_transaccion           varchar(5)  = null,
       @i_tasa                  money       = null,
       @i_monto_cv              money       = null,
       @i_mon                   tinyint     = null,
       @i_moneda_cv             tinyint     = null,
       @i_valor_tran            money       = null,
       @i_cot_usd               float       = 0,
       @i_factor                float       = 0,
       @i_concepto              catalogo    = null,
       @i_cliente               int         = 0,
       @i_modo                  int         = 1,
       @o_valor_convertido      money       = null out,    /* Monto equivalente en la moneda destino                                    */
       @o_cot_usd               float       = null out,    /* Cotizacion del dólar utilizada en la negociación (Tesoreria/Contabilidad) */
       @o_factor                float       = null out,    /* Factor de relación de la moneda respecto al dólar(Tesoreria/Contabilidad) */
       @o_cotizacion            float       = null out,    /* Cotizacion de la Moneda respecto a la moneda nacional                     */
       @o_valor_conver_orig     money       = null out
)
as 

declare @w_sp_name             varchar(32),      --Nombre de procedure
        @w_tipo_op             estado,           /* Tipo de Operaci¢n: Compra, Venta o Arbitraje                              */
        @w_mensaje_error       varchar(255),
        @w_mon_local           smallint,
        @w_mon_usd             smallint,
        @w_retorno             int,
        @w_cotizacion          float,
        @w_rpc_interfaz        varchar(128)
  
select @w_sp_name  = 'sp_divisas_credito'

---- VERSIONAMIENTO DEL PROGRAMA ----
if @t_show_version = 1
begin
    print 'Stored procedure sp_divisas_credito, Version 1.0.0.0'
    return 0
end

if @t_trn != 21860 and @i_operacion = 'C'
begin
     exec cobis..sp_cerror
          @t_from = @w_sp_name,
          @i_num  = 101183
     return 1
end

--Consulta la moneda local
select @w_mon_local = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'MLO'

select @w_mon_usd = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'CDOLAR'

if @i_operacion = 'C'
begin
     select @i_modo = 1 
     
     if @i_modo = 0
     begin
          if @i_mon != @w_mon_local and @i_moneda_cv != @w_mon_local and @i_mon != @i_moneda_cv
          begin
               exec cobis..sp_cerror  -- ERROR EN LA MONEDA DE COMPRA DE DIVISAS, ESCOJA LA MONEDA LOCAL
                    @t_from = @w_sp_name,
                    @i_num  = 2610063,
                    @i_sev  = 0
               return 1
          end

          if @i_moneda_origen = @w_mon_local and @i_moneda_destino = @w_mon_usd
             select @i_valor_destino = @i_valor, @i_valor = 0
          else
             select @i_valor = @i_valor, @i_valor_destino = 0

          select @w_rpc_interfaz = 'cob_sbancarios..sp_op_divisas_automatica'
    
          exec @w_retorno = @w_rpc_interfaz
               @s_ssn               = @s_ssn,                   /* Secuencial único COBIS                                                    */
               @s_user              = @s_user,                  /* Usuario del sistema                                                       */
               @s_date              = @s_date,                  /* Fecha del sistema                                                         */
               @i_oficina           = @i_oficina,               /* Oficina donde debe ser registrada la transacción.  Afectará contablemente */
               @i_modulo            = @i_modulo,                /* Nemónico del módulo COBIS que origina la operación de divisas             */
               @i_concepto          = 'NODE',                   /* Concepto de la negociaci¢n.  Valor del cat logo sb_divisas_modulos.  Se */
               @i_operacion         = @i_operacion,             /* C - Consulta, E - Ejecución normal , R - Reversar una operación anterior  */
               @i_cot_contable      = 'S',                      /* Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       */
               @i_moneda_origen     = @i_moneda_origen,         /* Moneda en la cual está expresado el monto a convertir                     */
               @i_valor             = @i_valor,                 /* Monto a convertir                                                         */
               @i_moneda_destino    = @i_moneda_destino,        /* Moneda en la cual se expresará el monto                                   */
               @i_valor_destino     = @i_valor_destino,         /* Monto destino a convertir al equivalente en moneda de origen              */
               @i_contabiliza       = 'N'    ,                  /* S para que la operaci=n sea contabilizada en SBancarios                   */
               @o_valor_convertido  = @o_valor_convertido out,  /* Monto equivalente en la moneda destino                                    */
               @o_valor_conver_orig = @o_valor_conver_orig out, /* Monto equivalente en la moneda origen                                     */
               @o_cot_usd           = @o_cot_usd out,           /* Cotización del dólar utilizada en la negociación (Tesoreria/Contabilidad) */
               @o_factor            = @o_factor out,            /* Factor de relación de la moneda respecto al dólar(Tesoreria/Contabilidad) */
               @o_cotizacion        = @o_cotizacion out,        /* Cotizacion de la Moneda respecto a la moneda nacional                     */
               @o_tipo_op           = @w_tipo_op out,           /* Tipo de Operaci¢n: Compra, Venta o Arbitraje                              */
               @o_msg_error         = @w_mensaje_error out,
               @i_batch             = 'N'

           if isnull(@w_mensaje_error,'') != ''
           begin
                print @w_mensaje_error
                return 1
           end
           
           if @i_moneda_origen = @w_mon_local and @o_valor_conver_orig != 1
              select @o_valor_convertido=@o_valor_conver_orig
      end 
      
      if @i_modo = 1
      begin
           select @o_cot_usd = ct_valor
           from cob_credito..cb_cotizaciones cot -- PQU integracion cob_cartera..cotizacion cot
           where ct_fecha = (select max(ct_fecha) 
                             from cob_credito..cb_cotizaciones--PQU integracion 
                             where ct_moneda = cot.ct_moneda)
             and ct_moneda = @w_mon_usd
                              
          if @i_moneda_origen = @i_moneda_destino
             select @w_cotizacion = 1
          else if @i_moneda_origen != @w_mon_local 
               begin
                    select @w_cotizacion = ct_valor
                    from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion cot
                    where ct_fecha = (select max(ct_fecha) from cob_cartera..cotizacion
                                      where ct_moneda = cot.ct_moneda)
                      and ct_moneda = @i_moneda_origen
              end
              else begin
                   select @w_cotizacion = ct_valor
                   from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion cot
                   where ct_fecha = (select max(ct_fecha) from cob_credito..cb_cotizaciones--PQU cob_cartera..cotizacion
                                     where ct_moneda = cot.ct_moneda)
                     and ct_moneda = @i_moneda_destino        
              end 
           
              select @o_cotizacion = @w_cotizacion
              select @o_cot_usd = @o_cotizacion
        
              if @i_moneda_origen = @i_moneda_destino
                 select @o_valor_convertido = @i_valor
              else if @w_mon_local = @w_mon_usd
                   begin
                        if @w_mon_local = @i_moneda_origen
                           select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
                        else 
                           select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
                   end
                   else begin                  
                        if @w_mon_local = @i_moneda_origen
                           select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
                        else
                           select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
                   end
        
                   select @o_valor_conver_orig = @o_valor_convertido
        
                   if @o_valor_convertido is null
                   begin
                        exec cobis..sp_cerror
                             @t_debug  =  @t_debug,
                             @t_file   =  @t_file,
                             @t_from   =  @w_sp_name,
                             @i_num    =  902659
                        return 902659
                  end                    
     end
end

if @i_operacion = 'Q'
begin
     if @i_oficina is null
        select @i_oficina = @s_ofi
        
     if @i_moneda_destino is null
        select @i_moneda_destino = @w_mon_local
       
     select @i_modo = 1
    
     if @i_modo = 0
     begin            
          select @w_rpc_interfaz = 'cob_sbancarios..sp_op_divisas_automatica'
    
          exec  @w_retorno = @w_rpc_interfaz
                @s_ssn               = @s_ssn,                   /* Secuencial único COBIS                                                    */
                @s_user              = @s_user,                  /* Usuario del sistema                                                       */
                @s_date              = @s_date,                  /* Fecha del sistema                                                         */                
                @i_oficina           = @i_oficina,               /* Oficina donde debe ser registrada la transacción.  Afectará contablemente */
                @i_modulo            = @i_modulo,                /* Nemónico del módulo COBIS que origina la operación de divisas             */
                @i_concepto          = 'NODE',                   /* Concepto de la negociaci¢n.  Valor del cat logo sb_divisas_modulos.  Se   */                
                @i_operacion         = 'C',                      /* C - Consulta, E - Ejecución normal , R - Reversar una operación anterior  */
                @i_cot_contable      = 'S',                      /* Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables       */
                @i_moneda_origen     = @i_moneda_origen,         /* Moneda en la cual está expresado el monto a convertir                     */
                @i_valor             = @i_valor,                 /* Monto a convertir                                                         */
                @i_moneda_destino    = @i_moneda_destino,        /* Moneda en la cual se expresará el monto                                   */
                @i_valor_destino     = @i_valor_destino,         /* Monto destino a convertir al equivalente en moneda de origen              */
                @i_contabiliza       = 'N'    ,                  /* S para que la operaci=n sea contabilizada en SBancarios                   */
                @o_valor_convertido  = @o_valor_convertido out,  /* Monto equivalente en la moneda destino                                    */
                @o_valor_conver_orig = @o_valor_conver_orig out, /* Monto equivalente en la moneda origen                                     */
                @o_cot_usd           = @o_cot_usd out,           /* Cotización del dólar utilizada en la negociación (Tesoreria/Contabilidad) */
                @o_factor            = @o_factor out,            /* Factor de relación de la moneda respecto al dólar(Tesoreria/Contabilidad) */
                @o_cotizacion        = @o_cotizacion out,        /* Cotizacion de la Moneda respecto a la moneda nacional                     */
                @o_tipo_op           = @w_tipo_op out,           /* Tipo de Operaci¢n: Compra, Venta o Arbitraje                              */
                @o_msg_error         = @w_mensaje_error out,
                @i_batch             = 'N'
                
          if isnull(@w_mensaje_error,'') != ''
          begin
              if @w_retorno != 0
                 return @w_retorno
              else
                 return 902659
          end
          
          if @w_retorno != 0
             return @w_retorno
     end    

     if @i_modo = 1
     begin
          select @o_cot_usd = ct_valor
          from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion cot
          where ct_fecha = (select max(ct_fecha) 
                            from cob_credito..cb_cotizaciones--PQU cob_cartera..cotizacion
                            where ct_moneda = cot.ct_moneda)
            and ct_moneda = @w_mon_usd
                             
         if @i_moneda_origen = @i_moneda_destino
            select @w_cotizacion = 1
         else if @i_moneda_origen != @w_mon_local 
              begin
                   select @w_cotizacion = ct_valor
                   from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion cot
                   where ct_fecha = (select max(ct_fecha) from cob_credito..cb_cotizaciones--PQU cob_cartera..cotizacion
                                     where ct_moneda = cot.ct_moneda)
                     and ct_moneda = @i_moneda_origen
             end
             else begin
                  select @w_cotizacion = ct_valor
                  from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion cot
                  where ct_fecha = (select max(ct_fecha) from cob_credito..cb_cotizaciones--PQU cob_cartera..cotizacion
                                    where ct_moneda = cot.ct_moneda)
                    and ct_moneda = @i_moneda_destino        
             end 
          
             select @o_cotizacion = @w_cotizacion
             select @o_cot_usd = @o_cotizacion
       
             if @i_moneda_origen = @i_moneda_destino
                select @o_valor_convertido = @i_valor
             else if @w_mon_local = @w_mon_usd
                  begin
                       if @w_mon_local = @i_moneda_origen
                          select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
                       else 
                          select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
                  end
     else begin                  
                       if @w_mon_local = @i_moneda_origen
                          select @o_valor_convertido = round(@i_valor / @o_cotizacion,2)
                       else
                          select @o_valor_convertido = round(@i_valor * @o_cotizacion,2)
                  end
       
                  select @o_valor_conver_orig = @o_valor_convertido
       
                  if @o_valor_convertido is null
                  begin
                       exec cobis..sp_cerror
                            @t_debug  =  @t_debug,
                            @t_file   =  @t_file,
                            @t_from   =  @w_sp_name,
                            @i_num    =  902659
                       return 902659
                 end                    
     end
end

return 0

GO