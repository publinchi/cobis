/************************************************************************/
/*   Archivo:                 cartliberec.sp                            */
/*   Stored procedure:        sp_reporte_carta_liber_recurso            */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Julio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Reporte de Carta de Liberación de Recursos                         */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   25/Jul/2019   Edison Cajas.   Emision Inicial                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_carta_liber_recurso')
    drop proc sp_reporte_carta_liber_recurso
go

create proc sp_reporte_carta_liber_recurso
(
   @t_trn              int          = 77519,
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(15),
   @i_nemonico         varchar(10),
   @i_formato_fecha    int          = 103
)
as 

declare
    @w_sp_name        varchar(30)      ,@w_error                int           ,@w_ciudad             varchar(30)
   ,@w_num_oficina    int              ,@w_sucursal_provincia   varchar(50)   ,@w_fecha              varchar(10)
   ,@w_sucursal       varchar(30)      ,@w_monto                money         ,@w_nro_credito        cuenta
   ,@w_cliente        varchar(30)      ,@w_simb_moneda          varchar(5)    ,@w_operacion          int
   ,@w_porc_liberar   varchar(10)      ,@w_porc_a_liberar       varchar(10)   ,@w_porc_pen_liberar   varchar(10)
   
   
   
select @w_sp_name = 'sp_reporte_carta_liber_recurso'

if @t_trn <> 77519
begin
    select @w_error = 151051		
    goto ERROR
end


    select
	     @w_operacion         = op_operacion
		,@w_num_oficina       = op_oficina 
	    ,@w_sucursal          = (select fi_nombre from cobis..cl_filial 
		                         where fi_filial = (select pa_tinyint
													from cobis..cl_parametro
													where pa_nemonico = 'FILIAL')) 
		,@w_cliente           = (select en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido  from cobis..cl_ente where en_ente = op_cliente)
		,@w_monto             = isnull(op_monto,0)
		,@w_nro_credito       = isnull(op_banco,'NA')	
		,@w_simb_moneda       = case op_moneda when 0 then 'M.N' else 'M.E' end
		,@w_fecha             = convert(varchar(10),GETDATE(),@i_formato_fecha)
	from cob_cartera..ca_operacion
    where op_banco = @i_banco

	if @@ROWCOUNT = 0
    BEGIN
       select @w_error = 1909005
	   goto ERROR
    END
	
	select @w_ciudad = ci_descripcion 
	from cobis..cl_ciudad
	where ci_ciudad = (
	      select of_ciudad 
	      from cobis..cl_oficina
		  where of_oficina = @w_num_oficina) 

	
	select @w_ciudad = isnull(@w_ciudad,'')
	
	if exists(select 1 from ca_dividendo where di_operacion = @w_operacion  and di_dividendo = 1 and di_estado <> 3)
    begin
       select @w_porc_liberar = '0%', @w_porc_a_liberar    = '50%', @w_porc_pen_liberar = '50%'
    end
   
    if exists(select 1 from ca_dividendo where di_operacion = @w_operacion and di_dividendo = 1 and di_estado = 3)
    begin
       select @w_porc_liberar = '50%', @w_porc_a_liberar    = '50%', @w_porc_pen_liberar = '0%'
    end 

    Select
	    @w_ciudad
		,@w_fecha
        ,@w_sucursal
 		,@w_cliente
		,@w_nro_credito
		,@w_monto
		,@w_simb_moneda
		,@w_porc_liberar
		,@w_porc_a_liberar
		,@w_porc_pen_liberar

return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   
return @w_error