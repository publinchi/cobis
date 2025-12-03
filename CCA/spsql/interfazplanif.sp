/************************************************************************/
/*   Archivo:                 interfazplanif.sp                         */
/*   Stored procedure:        sp_interfaz_planificador                  */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  Abr-2007                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */ 
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Este sp es llamado desde el programa pagoplanif.sp para            */
/*   la genracion del pago al planificador a sidac                      */
/*                          MODIFICACIONES                              */
/*  FECHA            AUTOR             RAZON                            */
/*                                                                      */
/************************************************************************/
use cob_cartera
go
 

if exists (select 1 from cob_cartera..sysobjects where name = 'sp_interfaz_planificador')
   drop proc sp_interfaz_planificador 
go

create proc sp_interfaz_planificador (
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 1,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 1,
   @s_srv                    varchar (30) = null,
   @s_ofi                    int          = 1,
   @i_operacionca            int,
   @i_dm_secuencial          int,
   @i_tramite                int,
   @i_op_oficina             int,
   @i_cto_sidac              catalogo,
   @i_fpago                  char(1),
   @i_exento                 char(1) = 'N',
   @i_debug                  char(1) = 'N'
)
as

declare 
   @w_sp_name                      varchar(20),
   @w_sec                          int,
   @w_error                        int,
   @w_cuenta_sidac                 int,
   @w_referencia_sidac             varchar(50),
   @w_ppt_ente_planificador        int,
   @w_descripcion                  varchar(50),
   @w_area                         smallint,
   @w_rp_saldo                     money,
   @w_ppt_monto                    money,
   @w_factura                      int,
   @w_ppt_referencia               cuenta,
   @w_ppt_porcentaje               float,
   @w_ofi_centralizadora           int,
   @w_rowcount                     int
   
  

select @w_sp_name = 'sp_interfaz_planificador',
       @w_sec = 0,
       @w_cuenta_sidac = 0,
       @w_factura      = 0



select @w_ofi_centralizadora = pa_int
from   cobis..cl_parametro
where  pa_producto = 'CON'
and pa_nemonico = 'OFC'
set transaction isolation level read uncommitted

/*Mroa: comentado para Fase I de Bancamia

declare  pago_planificadores  cursor for
select 
    ppt_monto,
    ppt_ente_planificador,
    ppt_referencia,
    ppt_porcentaje
                      
from  ca_pago_planificador_tmp
where ppt_operacion = @i_operacionca
and ppt_secuencial_des = @i_dm_secuencial
and ppt_usuario = @s_user


for read only

open   pago_planificadores
fetch pago_planificadores into

    @w_ppt_monto,
    @w_ppt_ente_planificador,
    @w_ppt_referencia,
    @w_ppt_porcentaje       


--while   @@fetch_status  not in (-1, 0 )
while   @@fetch_status  = 0
begin

      --AREA PARAMETRIZADA PARA EL CONCEPTO

      if @s_ofi = @w_ofi_centralizadora
       begin
         select @w_area = pa_int
         from   cobis..cl_parametro
         where  pa_producto = 'CCA'
         and pa_nemonico = 'AROFCE'
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted

        if @w_rowcount = 0
            return 721007           
       end
       ELSE 
       begin
         select @w_area = pa_int
         from   cobis..cl_parametro
         where  pa_producto = 'CCA'
         and    pa_nemonico  =  'ARCXP'
         and    pa_producto = 'CCA'
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted

        if @w_rowcount = 0
            return 721002         
       end

      --GENERAR NOTA DE CUENTA POR PAGAR A SIDAC 
      select @w_referencia_sidac = convert(varchar, @i_tramite)

      exec @w_error = cob_sidac..sp_cuentaxpagar   
           @s_ssn               =  @s_ssn,
           @s_user              =  @s_user,
           @s_date              =  @s_date,
           @s_term              =  @s_term,
           @s_ssn_corr          =  @s_ssn,
           @s_srv               =  @s_srv, 
           @s_ofi               =  @s_ofi,
           @t_trn               =  32550,
           @i_operacion         = 'I',
           @i_empresa           =  1,
           @i_fecha_rad         =  @s_date,
           @i_modulo            =  7,
           @i_fecha_ven         =  @s_date,            
           @i_fecha_doc         =  @s_date,
           @i_moneda            =  0,           
           @i_valor             =  @w_ppt_monto, 
           @i_concepto          =  @i_cto_sidac,
           @i_condicion         = '01',             
           @i_tipo_referencia   = '01',
           @i_formato_fecha     =  101,             
           @i_ente              =  @w_ppt_ente_planificador,      
           @i_referencia        =  @w_referencia_sidac,
           @i_area              =  @w_area,
           @i_oficina           =  @s_ofi,
           @i_estado            = 'P',
           @i_descripcion       =  'PAGO PLANIFICADORES AUTOMATICO DES-CARTERA',
           @i_geniva            =  1,
           @o_cuenta	           =  @w_cuenta_sidac  out
      
            if @w_error  != 0
               return @w_error
               
            if @w_cuenta_sidac = 0 or @w_cuenta_sidac is null
            return 721004

            --Obtener el nurmero de la factura
            select @w_factura = cf_cuenta 
            from cob_sidac..sid_conceptos_facturas 
            where  cf_cuenta_pagar = @w_cuenta_sidac
            
            if @@rowcount  =  0
            return 721005
             
            ---Sacar el saldo de la cuenta
            select @w_rp_saldo  = sum(isnull(rp_saldo,0))
            from cob_sidac..sid_registros_padre 
            where rp_consecutivo = @w_cuenta_sidac
            and rp_submodulo = 'CP'                
        
        
             if @i_debug = 'S'
                PRINT 'interfazplanif.sp @w_rp_saldo para pago,  @w_ppt_porcentaje'+ CAST(@w_rp_saldo AS VARCHAR) + CAST(@w_ppt_porcentaje AS VARCHAR)
  
        
       ---Registro de Pago en SIDAC
       if   @w_rp_saldo > 0
         begin
           exec @w_error  = cob_sidac..sp_pagos_parciales
                @s_ssn         =  @s_ssn,
                @s_user        =  @s_user,
                @s_date        =  @s_date,
                @s_term        =  @s_term,
                @s_ssn_corr    =  @s_ssn,
                @s_srv         =  @s_srv, 
                @s_ofi         =  @s_ofi,
                @t_trn         = 32860,
                @i_operacion   = "I",
                @i_empresa     = 1,
                @i_submodulo   =  "CP",
                @i_factura     = @w_factura,
                @i_valor       = @w_rp_saldo,
                @i_ente        = @w_ppt_ente_planificador,
                @i_ftipo       = @i_fpago,
                @i_subtipo     = @w_ppt_referencia
   
            if @w_error  != 0
            begin
               PRINT 'interfazplanif.sp saliendo de cob_sidac..sp_pagos_parciales  ->' + CAST(@w_error AS VARCHAR)
               return 721003
            end 
 
             ---Para Autorizar el pago parcial: 
            if @w_ppt_porcentaje > 40
            begin
               exec @w_error  = cob_sidac..sp_facturas
               @s_ssn               =  @s_ssn,
               @s_user              =  @s_user,
               @s_date              =  @s_date,
               @s_term              =  @s_term,
               @s_ssn_corr          =  @s_ssn,
               @s_srv               =  @s_srv, 
               @s_ofi               =  @s_ofi,
               @t_trn               = 32585,
               @i_operacion         = "T",
               @i_estado            = "P",
               @i_modo              =  0,
               @i_empresa           = 1,
               @i_cuenta            = @w_factura
   
                if @w_error  != 0
                   return @w_error
            end
                  
            end --pago
           
            if @w_cuenta_sidac > 0
            begin
               
               if  @w_ppt_porcentaje  = 60
                  update  ca_pago_planificador_tmp
                  set  ppt_cuenta_sidac = @w_cuenta_sidac
                  where ppt_operacion = @i_operacionca
                  and ppt_secuencial_des = @i_dm_secuencial
                  and ppt_usuario = @s_user
                  and ppt_porcentaje =  60
                  
                  
               if  @w_ppt_porcentaje  = 40
                  update  ca_pago_planificador_tmp
                  set  ppt_cuenta_sidac_aux = @w_cuenta_sidac
                  where ppt_operacion = @i_operacionca
                  and ppt_secuencial_des = @i_dm_secuencial
                  and ppt_usuario = @s_user
                  and ppt_porcentaje =  60

               if  @w_ppt_porcentaje  = 100
                  update  ca_pago_planificador_tmp
                  set  ppt_cuenta_sidac_aux = 0,
                       ppt_cuenta_sidac = @w_cuenta_sidac
                  where ppt_operacion = @i_operacionca
                  and ppt_secuencial_des = @i_dm_secuencial
                  and ppt_usuario = @s_user
                  and ppt_porcentaje =  100               
               
            end
         
         
         fetch pago_planificadores into
         
       @w_ppt_monto,
       @w_ppt_ente_planificador,
       @w_ppt_referencia,
       @w_ppt_porcentaje

end ---cursor
close pago_planificadores
deallocate pago_planificadores

*/ 
  

return 0

go

