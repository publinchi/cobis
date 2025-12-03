/************************************************************************/
/*      Archivo:                segurogrp.sp                            */
/*      Stored procedure:       sp_seguros_grp                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Junio-2019                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de Seguros y Ordenes de Pago de la operacion      */
/*      grupal                                                          */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*     04-07-19     Adriana Giler       Ajustes version Grupal          */
/*     08-07-19     Adriana Giler       Operacion RefREn Grupal         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_seguros_grp')
    drop proc sp_seguros_grp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_seguros_grp
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @s_ofi               smallint     = null,
   @i_opcion            char(1),                 
   @i_cliente           int,  
   @i_oper_padre        int,
   @i_oper_hija         int,
   @i_sesion            int,
   @o_mensaje           varchar(100) = null out
    

as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_msg               mensaje,
   @w_producto          smallint,
   @w_tipo_iden         varchar(10),
   @w_identificacion    varchar(32),
   @w_nombres           varchar(100),
   @w_apellido_paterno  varchar(100),
   @w_apellido_materno  varchar(100),
   @w_porcentaje        float,
   @w_parentezco        varchar(10),
   @w_secuencia         int,
   @w_ente              int,
   @w_fecha_mod         datetime,
   @w_fecha_nac         datetime,
   @w_telefono          varchar(20),
   @w_direccion         varchar(70),
   @w_provincia         smallint,
   @w_ciudad            smallint,
   @w_parroquia         int,
   @w_codpostal         varchar(10),        --AGI TEC
   @w_localidad         varchar(20),
   @w_sec_direccion     int,
   @w_ente_benef        int
   
select @w_producto = 7
  
if @i_opcion = 'I' -- Ingreso de Seguros
begin
    --Insert datos del Seguro     
    insert ca_seguros_op (
            so_cliente,          so_tipo_seguro,     so_monto_seguro,  
            so_fecha_inicial,    so_operacion,       so_oper_padre,     
            so_user,             so_ofi,             so_fecha_proceso,            
            so_estado,           so_folio,           so_fecha_fin)                         --AGC 04JUL19
    select
            @i_cliente,          ist_tipo_seguro,    ist_monto_seguro, 
            ist_fecha_inicial,   @i_oper_hija,       @i_oper_padre,      
            @s_user,             @s_ofi,             @s_date,
            'I',                 ist_folio,          ist_fecha_final         --AGC 04JUL19
    from  ca_interf_seguros_tmp
    where ist_cliente = @i_cliente
    and   ist_sesn  = @i_sesion
    
    if @@error != 0
    begin
        select @o_mensaje  = 'Error. Ingresando Datos del Seguro.'
        return 725040
    end

    --Insert beneficiarios del Seguro si tuviere
    if exists(select 1 from ca_interf_benef_tmp, ca_interf_hijas_tmp
              where iht_operacion = @i_oper_padre 
              and iht_cliente = @i_cliente
              and iht_sesn  = @i_sesion
              and ibt_cliente = iht_cliente
              and ibt_sesn    = iht_sesn)    
    begin
        select @w_secuencia = 0
        
        select @w_secuencia = isnull(max(bs_secuencia),0) 
        from cobis..cl_beneficiario_seguro
        where bs_nro_operacion = @i_oper_hija
        and  bs_producto = @w_producto
        
        declare cur_beneficiario cursor
        for select ibt_cliente,             ibt_nombres,        ibt_apellido_paterno, 
                   ibt_apellido_materno,    ibt_porcentaje,     ibt_parentezco,       
                   ibt_telefono,            ibt_codigo_postal,  ibt_fecha_nacimiento,
                   (trim(ibt_calle) + "|" + trim(ibt_nro_exterior) + "|" + trim(ibt_nro_interior))    --AGC 04JUL19  
        from   ca_interf_benef_tmp 
        where  ibt_cliente = @i_cliente
        and    ibt_sesn    = @i_sesion       
        for read only
       
        open cur_beneficiario
        fetch cur_beneficiario
        into  @w_ente_benef,       @w_nombres,          @w_apellido_paterno, 
              @w_apellido_materno, @w_porcentaje,       @w_parentezco,       
              @w_telefono,         @w_codpostal,        @w_fecha_nac,
              @w_direccion                         --AGC 04JUL19
              
        while   @@fetch_status = 0 
        begin 
            if (@@fetch_status = -1) 
            begin
                select @o_mensaje  = 'Error Ingresando Datos del Beneficiario.',
                       @w_error    = 725041
                GOTO ERROR
            end
          
            --AGC 04JUL19   Obtener datos de Estado/Municipio/Colonia
            select @w_tipo_iden      = null,        
                   @w_identificacion = null
            
            
            select @w_localidad = null,
                   @w_provincia = null,
                   @w_parroquia = null,
                   @w_ciudad    = null
                   
            select @w_provincia = cp_estado,
                   @w_parroquia = cp_colonia,
                   @w_ciudad    = cp_municipio
            from cobis..cl_codigo_postal
            where cp_codigo = @w_codpostal
            
            if @@rowcount = 0
            begin
                select @o_mensaje  = 'Error Ingresando Datos del Beneficiario.',
                       @w_error    = 50020
                GOTO ERROR
            end
            
            --FIN AGC
           
            select @w_secuencia = @w_secuencia  + 1
            
            insert cobis..cl_beneficiario_seguro 
                   (bs_nro_operacion,     bs_producto,          bs_tipo_id,     bs_ced_ruc,         bs_nombres,
                    bs_apellido_paterno,  bs_apellido_materno,  bs_porcentaje,  bs_parentesco,      bs_secuencia,
                    bs_ente,              bs_fecha_mod,         bs_fecha_nac,   bs_telefono,        bs_direccion,
                    bs_provincia,         bs_ciudad,            bs_parroquia,   bs_codpostal,       bs_localidad      
                    )
            values (
                    @i_oper_hija,         @w_producto,          @w_tipo_iden,   @w_identificacion,  @w_nombres,
                    @w_apellido_paterno,  @w_apellido_materno,  @w_porcentaje,  @w_parentezco,      @w_secuencia,
                    @w_ente,              @s_date,              @w_fecha_nac,   @w_telefono,        @w_direccion,
                    @w_provincia,         @w_ciudad,            @w_parroquia,   @w_codpostal,       @w_localidad
                    )
                    
            if @@error != 0
            begin
                select @o_mensaje  = 'Error Ingresando Datos del Beneficiario.',
                       @w_error    = 725041              
                GOTO ERROR
                
            end
            
            fetch cur_beneficiario
            into  @w_ente_benef,       @w_nombres,          @w_apellido_paterno, 
                  @w_apellido_materno, @w_porcentaje,       @w_parentezco,       
                  @w_telefono,         @w_codpostal,        @w_fecha_nac,
                  @w_direccion                         --AGC 04JUL19
                  
        end --WHILE CURSOR RUBROS

        close cur_beneficiario
        deallocate cur_beneficiario  
    end
    
    --Actualizar orden de Pago   
    update ca_interf_ordenp_tmp
    set iot_oper_hija = @i_oper_hija
    where iot_cliente = @i_cliente
      and iot_sesn    = @i_sesion
      
    if @@error != 0
    begin
        select @o_mensaje  = 'Error Actualizando Orden de Pago.',
               @w_error    = 725042            
        return 725042        
    end
end

return 0


ERROR:
    close cur_beneficiario
    deallocate cur_beneficiario 
    return @w_error

go

