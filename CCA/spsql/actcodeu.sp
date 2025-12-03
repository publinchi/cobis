/************************************************************************/
/*	Archivo: 		            actcodeu.sp			                        */
/*	Stored procedure: 	      sp_actualiza_codeudor				         */
/*	Base de datos:  	         cobis					                        */
/*	Producto: 		            Credito y Cartera			                  */
/*	Disenado por:  		      Xavier Maldonado				               */
/*	Fecha de escritura: 	      02-Jul-2005				                     */
/************************************************************************/
/*				                    IMPORTANTE				                  */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	'MACOSA'                                                             */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				                     PROPOSITO				                  */
/*	Este programa actualiza los codeudores de una operacion VIGENTE      */
/************************************************************************/  
/*				                     MODIFICACIONES				               */
/*	    FECHA		      AUTOR		              RAZON				         */
/*     MAY-2006         E.Pelaez         DEF-6611 nueva tabla           */
/*     SEP-2006         E.Pelaez         DEF-7185 borrado de deusdores  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_codeudor')
	drop proc sp_actualiza_codeudor
go
create proc sp_actualiza_codeudor (
	        @s_ssn			int = NULL,
	        @s_user			login = NULL,
	        @s_sesn			int = NULL,
	        @s_term			varchar(30) = NULL,
	        @s_date			datetime = NULL,
	        @s_srv			varchar(30) = NULL,
	        @s_lsrv			varchar(30) = NULL, 
	        @s_rol			smallint = NULL,
	        @s_ofi			smallint = NULL,
	        @s_org_err		char(1) = NULL,
	        @s_error		int = NULL,
	        @s_sev			tinyint = NULL,
	        @s_msg			descripcion = NULL,
	        @s_org			char(1) = NULL,
	        @t_debug		char(1) = 'N',
	        @t_file			varchar(14) = null,
	        @t_from			varchar(32) = null,
 	        @t_trn			smallint = null,
            @i_operacion	char(1),
            @i_banco        char(24),
		    @i_rol		    catalogo = null,
		    @i_codeudor	    int      = null,
            @i_ced_ruc      numero   = null,
		    @i_borrar	    char(1) = 'N'
)
as
declare		    @w_sp_name	  varchar(30),
                @w_max_sec        int,
                @w_fecha_ingreso  datetime,
                @w_tramite        int,
                @w_det_producto   int,
                @w_cliente_ec     int,
                @w_ced_ruc        varchar(30),
                @w_error          int,
                @w_operacionca    int,
                @w_op_naturaleza  char(1),
                @w_op_estado      tinyint

select @w_sp_name = 'sp_actualiza_codeudor',
       @w_fecha_ingreso  =  getdate()



select @w_tramite       = op_tramite,
       @w_cliente_ec    = op_cliente,
       @w_operacionca   = op_operacion,
       @w_op_naturaleza = op_naturaleza,
       @w_op_estado     = op_estado
from ca_operacion
where op_banco = @i_banco



select @w_det_producto = dp_det_producto
from cobis..cl_det_producto
where dp_cuenta     = @i_banco
and   dp_cliente_ec = @w_cliente_ec
and   dp_producto   = 7



select @w_ced_ruc = en_ced_ruc 
from cobis..cl_ente
where en_ente = @i_codeudor


if @i_operacion = 'I'
begin 
    if @w_op_estado = 0
    begin
        if exists (select 1 from cob_credito..cr_deudores
                   where de_tramite = @w_tramite
                   and   de_cliente = @i_codeudor)
        begin
            delete cob_credito..cr_deudores
            where de_tramite = @w_tramite
            and   de_cliente = @i_codeudor
        end

        insert into cob_credito..cr_deudores
        values (@w_tramite, @i_codeudor, @i_rol, @w_ced_ruc, null, 'N')

        if @@error != 0 
        begin
            --PRINT 'actcodeu.sp entro nro. 1 @w_tramite %1! @i_codeudor %2!' + @w_tramite + @i_codeudor
            select @w_error =  708154
            goto ERROR
        end

        if exists (select 1 from cobis..cl_cliente
                   where cl_det_producto = @w_det_producto
                   and   cl_cliente = @i_codeudor)
        begin
            delete cobis..cl_cliente
            where cl_det_producto = @w_det_producto
            and   cl_cliente = @i_codeudor
        end 

        insert into cobis..cl_cliente
        values (@i_codeudor, @w_det_producto, @i_rol, @w_ced_ruc, @w_fecha_ingreso)

        if @@error != 0 
        begin
            --PRINT 'actcodeu.sp entro nro. 2 @w_tramite %1! @i_codeudor %2!' + @w_tramite + @i_codeudor
            select @w_error =  708154
            goto ERROR
        end

        if exists (select 1 from cob_cartera..ca_deu_segvida
                   where dt_operacion = @w_operacionca
                   and   dt_cliente  = @i_codeudor )
        begin
            delete cob_cartera..ca_deu_segvida
            where dt_operacion = @w_operacionca
            and   dt_cliente  = @i_codeudor 
        end              

        insert into cob_cartera..ca_deu_segvida
        values (@w_operacionca, @i_codeudor,  @i_rol,'N', 'N' )

        if @@error != 0 
        begin
            --PRINT 'actcodeu.sp entro nro. 3 @w_tramite %1! @i_codeudor %2!' + @w_tramite + @i_codeudor
            select @w_error =  708154
            goto ERROR
        end
    end
    else
    begin
        select @w_error =  701189 --'Nose permite cambio de deudores en operaciones activas
        goto ERROR
    end
end


if @i_operacion = 'D'
begin
    if @w_op_estado = 0
    begin
        delete cob_credito..cr_deudores
        where de_cliente  = @i_codeudor
        and   de_tramite  = @w_tramite
        and   de_rol      = @i_rol

        if @@error != 0 
        begin
            select @w_error =  708155
            goto ERROR
        end
     
        delete cobis..cl_cliente
        where cl_cliente       = @i_codeudor
        and   cl_det_producto  = @w_det_producto
        and   cl_rol           = @i_rol

        if @@error != 0 
        begin
            select @w_error =  708155
            goto ERROR
        end

        delete cob_cartera..ca_deu_segvida
        where dt_operacion     = @w_operacionca
        and   dt_cliente       = @i_codeudor
        and   dt_rol           = @i_rol

        if @@error != 0 
        begin
            select @w_error =  708155
            goto ERROR
        end
    end  
    else
    begin
        select @w_error =  701189 --'No se permite cambio de deudores en operaciones activas
        goto ERROR
    end
end

return 0

ERROR:

exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_num   = @w_error
return @w_error    

go




