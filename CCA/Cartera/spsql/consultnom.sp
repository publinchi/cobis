/************************************************************************/
/*   Archivo:              consultnom.sp                                */
/*   Stored procedure:     sp_consulta_nombre                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   26/10/2021                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Proceso creado para realizar la consulta de pago por medio          */
/*  de un web service                                                   */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 26/10/2021     J. Hernandez       Versión inicial                    */
/* 26/10/2021     G. Fernandez       Correcion de nombre SP para log    */
/************************************************************************/

USE cob_cartera
GO



if exists(select 1 from sysobjects where name ='sp_consulta_nombre')
   drop proc sp_consulta_nombre
go

create proc sp_consulta_nombre
(
	
	@i_banco                varchar(30)   ,	
	@o_nombre_cliente   	varchar(220)  = null out    
	
)
as DECLARE
@w_sp_name          varchar(64),
@w_error		    int,
@w_return           int,
@w_cod_cliente      int,
@w_nombre           varchar(255),
@w_p_nombre         varchar(255),
@w_s_nombre         varchar(255),
@w_p_apellido       varchar(64),
@w_s_apellido       varchar(64),
@w_resto_nombre     varchar(255),
@w_nombre_cliente   varchar(20)

select @w_sp_name = 'sp_consulta_nombre'

select @w_cod_cliente = op_cliente from cob_cartera..ca_operacion
where op_banco =  @i_banco

if @@rowcount <> 1
begin
    return 710200
end

select @w_nombre     =  en_nombre,
	   @w_p_nombre   =  isnull(SUBSTRING(en_nombre, 0, CHARINDEX(' ', en_nombre)),''),
       @w_p_apellido =  isnull(p_p_apellido,''),
	   @w_s_apellido =  isnull(p_s_apellido,'')  
from cobis..cl_ente
where en_ente =@w_cod_cliente

if(@w_p_nombre <> null or @w_p_nombre <> '')
begin
    select
	    @w_p_nombre     = isnull(SUBSTRING(en_nombre, 0, CHARINDEX(' ', en_nombre)),''),
	    @w_resto_nombre = isnull(SUBSTRING(en_nombre, CHARINDEX(' ', en_nombre)+1,LEN(en_nombre)),'')
    from cobis..cl_ente
    where en_ente = @w_cod_cliente

	select 
	    @w_s_nombre     =  isnull(SUBSTRING(@w_resto_nombre, 0, CHARINDEX(' ', @w_resto_nombre)),''),
	    @w_resto_nombre = isnull(SUBSTRING(@w_resto_nombre, CHARINDEX(' ', @w_resto_nombre)+1,LEN(@w_resto_nombre)),'')
		
	if (@w_p_apellido = null or @w_p_apellido = '') and (@w_s_apellido = null or @w_s_apellido= '')
	begin
	    if(@w_s_nombre <> null or @w_s_nombre <> '')
        begin
	       select  @w_p_apellido   =  isnull(SUBSTRING(@w_resto_nombre, 0, CHARINDEX(' ', @w_resto_nombre)),''),
	        @w_resto_nombre = isnull(SUBSTRING(@w_resto_nombre, CHARINDEX(' ', @w_resto_nombre)+1,LEN(@w_resto_nombre)),'')
	    end
		else
		begin
		    select @w_s_nombre     =   @w_resto_nombre,
			       @w_resto_nombre =   ''
	    end
	    if(@w_p_apellido <> null or @w_p_apellido <> '')
	        select @w_s_apellido   =   @w_resto_nombre
		else 
		    select @w_p_apellido  =   @w_resto_nombre
		
	end
	
end
else
begin
    select @w_p_nombre = @w_nombre
end


if (@w_s_nombre <> '' or @w_s_nombre <> null)  and (@w_p_apellido <> '' or @w_p_apellido <> null) 
   select @w_nombre_cliente = @w_p_nombre +  SUBSTRING(@w_s_nombre, 1, 1) + SUBSTRING(@w_p_apellido, 1, 1)
if (@w_p_apellido <> '' or @w_p_apellido <> null)  and (@w_s_apellido <> '' or @w_s_apellido <> null) 
   select @w_nombre_cliente = @w_p_nombre +  SUBSTRING(@w_p_apellido, 1, 1) + SUBSTRING(@w_s_apellido, 1, 1)
if (@w_s_nombre = '' or @w_s_nombre is null)  and (@w_s_apellido = '' or @w_s_apellido is null) and (@w_p_apellido <> '' or @w_p_apellido <> null)
   select @w_nombre_cliente = @w_p_nombre +  SUBSTRING(@w_p_nombre, 1, 1) + SUBSTRING(@w_p_apellido, 1, 1)
if (@w_s_nombre <> '' or @w_s_nombre <> null)  and (@w_s_apellido = '' or @w_s_apellido is null) and (@w_p_apellido = '' or @w_p_apellido = null)
   select @w_nombre_cliente = @w_p_nombre +  SUBSTRING(@w_p_nombre, 1, 1) + SUBSTRING(@w_p_apellido, 1, 1)

select @o_nombre_cliente = @w_nombre_cliente

return 0

go