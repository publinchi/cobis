/***********************************************************************/
/*     Archivo:                 sp_tr_datos_adicionales.sp             */
/*     Stored procedure:        sp_tr_datos_adicionales                */
/*     Base de Datos:           cob_credito                            */
/*     Producto:                Credito                                */
/*     Disenado por:            IOR                                    */
/*     Fecha de Documentacion:  02/08/2012                             */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*     Este programa es parte de los paquetes bancarios propiedad de   */
/*     "MACOSA".                                                       */
/*     Su uso no autorizado queda expresamente prohibido asi como      */
/*     cualquier autorizacion o agregado hecho por alguno de sus       */
/*     usuario sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de MACOSA o su representante              */
/***********************************************************************/
/*                            PROPOSITO                                */
/*     Otros datos personalizacion HSBC                                */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*     FECHA           AUTOR           RAZON                           */
/*     02/08/2012      IOR             Emision Inicial                 */
/*                                                                     */
/***********************************************************************/
use cob_credito
go

if exists (select * from sysobjects where name = 'sp_tr_datos_adicionales')
	drop proc sp_tr_datos_adicionales
go

create proc sp_tr_datos_adicionales (
     @s_ssn             int         = null,
     @s_user            login       = null,
     @s_sesn            int         = null,
     @s_term            varchar(30) = null,
     @s_date            datetime    = null,
     @s_srv             varchar(30) = null,
     @s_lsrv		 	varchar(30) = null,
     @s_rol             smallint    = NULL,
     @s_ofi             smallint    = NULL,
     @s_org_err         char(1)     = NULL,
     @s_error           int         = NULL,
     @s_sev             tinyint     = NULL,
     @s_msg             descripcion = NULL,
     @s_org             char(1)     = NULL,
     @t_rty             char(1)     = null,
     @t_trn             smallint    = null,
     @t_debug           char(1)     = 'N',
     @t_file            varchar(14) = null,
     @t_from            varchar(30) = null,
     @t_show_version    bit         = 0, -- Mostrar la version del programa
     @i_operacion       char(1),
     @i_tramite         int,
     @i_sindicado       char(1)     = 'N',
     @i_tipo_cartera    catalogo    = null

)
as

declare @w_return       int,
        @w_numero       int,
        @w_sp_name      varchar(30),
        @w_existe       tinyint,
        @w_tabla        varchar(50),
        @w_operacion    int,
        @w_tipo_campo   varchar(30)
		
-------VERSIONAMIENTO DEL PROGRAMA---------------------------
if @t_show_version = 1
begin
    print 'Stored procedure sp_tr_datos_adicionales, Version 4.0.0.0'
    return 0
end
--------------------------------------------------------------
	
select @w_return = 0
select @w_sp_name= 'sp_tr_datos_adicionales'


-- Codigos de Transacciones
if @t_trn <> 21118
begin --Tipo de transaccion no corresponde
   select @w_return = 2101006
   goto ERROR
end
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if   @i_tramite = NULL 
    begin
        --Campos NOT NULL con valores nulos
        select @w_return = 2101001
        goto ERROR
    end
end

-- Chequeo de Existencias 
/*if @i_operacion <> 'S' 
begin
    if exists(select  1 from cob_credito..cr_tr_datos_adicionales
              where tr_tramite = @i_tramite)
            select @w_existe = 1
    else
            select @w_existe = 0
end*/

if @i_operacion = 'I'
begin
    /*if @w_existe = 1
    begin
       --Registro ya existe 
       select @w_return = 2101002
       goto ERROR
    end*/
    begin tran
        
        
        insert into cr_tr_datos_adicionales (tr_tramite, tr_tipo_cartera)
        values(@i_tramite, @i_tipo_cartera)
        
        if @@error !=  0
        begin
            --error en insercion
            select @w_return = 2103001
            goto ERROR
        end


        --si aplica insertar datos en CCA 
        if exists(select 1 from cr_tramite where tr_producto = 'CCA' and tr_tramite = @i_tramite)
        begin
                select @w_operacion = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite

                if not exists (select 1 from cob_cartera..ca_op_datos_adicionales where  op_operacion = @w_operacion)
                begin
                    insert into cob_cartera..ca_op_datos_adicionales(op_operacion, op_tipo_cartera, op_sindicado)
                    values(@w_operacion, @i_tipo_cartera, @i_sindicado)

                    if @@error !=  0
                    begin
                        --error en insercion
                        select @w_return = 2103001
                        goto ERROR
                    end
               end
               else
               begin
                    update cob_cartera..ca_op_datos_adicionales 
                    set   op_tipo_cartera = @i_tipo_cartera,
                    op_sindicado = @i_sindicado
                    where op_operacion = @w_operacion

                    if @@error !=  0
                    begin
                        --Error en Actualizacion 
                        select @w_return = 2105001
                        goto ERROR
                    end
               end
         end
    commit tran
end

if @i_operacion = 'U'
begin
    /*if @w_existe = 0
    begin
       -- Registro a actualizar no existe
       select @w_return = 2105002
       goto ERROR
       --return 1 
    end*/
    begin tran
    update cr_tr_datos_adicionales 
    set   --tr_sindicado = @i_sindicado,
          tr_tipo_cartera = @i_tipo_cartera
    where tr_tramite = @i_tramite
          
    if @@error !=  0
    begin
        --Error en Actualizacion 
        select @w_return = 2105001
        goto ERROR
    end

     --si aplica actualizar datos en CCA
        if exists(select 1 from cr_tramite where tr_producto = 'CCA' and tr_tramite = @i_tramite)
        begin
            select @w_operacion = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite

            update cob_cartera..ca_op_datos_adicionales 
            set   op_tipo_cartera = @i_tipo_cartera,
            op_sindicado = @i_sindicado
            where op_operacion = @w_operacion
                  
            if @@error !=  0
            begin
                --Error en Actualizacion 
                select @w_return = 2105001
                goto ERROR
            end
    end

    commit tran
end

if @i_operacion = 'D'
begin
    delete cr_tr_datos_adicionales 
    where tr_tramite = @i_tramite

    if @@error !=  0
    begin       
        --Error en eliminacion
        select @w_return = 2107001
        goto ERROR
    end

    --si aplica eliminar datos en CCA
    if exists(select * from cr_tramite where tr_producto = 'CCA' and tr_tramite = @i_tramite)
    begin
        select @w_operacion = op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite

        delete cob_cartera..ca_op_datos_adicionales 
        where op_operacion = @w_operacion

        if @@error !=  0
        begin
            --Error en Actualizacion 
            select @w_return = 2105001
            goto ERROR
        end
    end

end


return 0

ERROR:
   --Devolver mensaje de Error
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = @w_return
    return @w_return



GO

