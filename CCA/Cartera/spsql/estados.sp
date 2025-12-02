/************************************************************************/
/*	Archivo: 		estados.sp				                            */
/*	Stored procedure: 	sp_estados				                        */
/*	Base de datos:  	cob_cartera				                        */
/*	Producto: 		Credito y Cartera			                        */
/*	Disenado por:  		Fabian Espinosa				                    */
/*	Fecha de escritura: 	10-Mar-1995				                    */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"MACOSA".							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Este programa obtiene los codigos de estado definidos en el	        */
/*	sistema								                                */
/************************************************************************/  
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		RAZON				                        */
/*	10-Mar_1995	F.Espinosa	Emision inicial			                    */
/*	18-Oct_2016	N.Vite		Migracion Cobis Cloud	                    */
/*	28-Dic_2021	G.Fernandez	Cambio de tipo de parametro de @i_estado_ini*/
/*	                        de catálogo a descripción por que truncaba  */
/*	                        el texto                                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_estados')
	drop proc sp_estados
go
create proc sp_estados (
            @t_trn              INT         = NULL, --LPO CDIG Cambio de Servicios a Blis                  
            @i_operacion 		char(1)     = 'C',
	        @i_toperacion 		varchar(10) = null,
            @i_estado_ini       descripcion = null,
            @i_codigo		    varchar(10) = null,
 	        @i_categoria	    int	        = NULL,
            @i_cond1            char(1)     = null,
            @i_parametro        tinyint     = null
			
)
as

declare
   @w_sp_name		varchar (32),
   @w_error         int,
   @w_msg			varchar(132)

declare @w_estados_excluidos	table(estado int)

/*  Captura nombre de Stored Procedure e Inicializa Variables  */

select	@w_sp_name = 'sp_estados'

if @i_categoria = 2
begin 
	insert into @w_estados_excluidos
	select es_codigo
	  from cob_cartera..ca_estado
	 where es_descripcion <> 'NO VIGENTE'
end
else if @i_categoria = 3 
begin
	insert into @w_estados_excluidos
	select es_codigo
	  from cob_cartera..ca_estado
	 where es_descripcion = 'NO VIGENTE'
end
else if @i_categoria = 4 
begin
	insert into @w_estados_excluidos
	select es_codigo
	  from cob_cartera..ca_estado
	 where es_descripcion in ('NO VIGENTE', 'CANCELADO')
end
else if @i_categoria =5
begin
	insert into @w_estados_excluidos
	select es_codigo
	  from cob_cartera..ca_estado
	 where es_descripcion = 'CANCELADO'	
end


if @i_operacion = 'H'
   select 'Descripción' =  es_descripcion from ca_estado

if @i_operacion = 'C'   --Estados de condonacion
begin
   select 
         'Codigo'      = es_codigo,
         'Descripción' =  es_descripcion from ca_estado
   where  es_codigo in (1,4)
end

if @i_operacion = 'V' --Busqueda estado de condonación
begin
	select es_descripcion 
    from ca_estado
	where es_codigo = @i_codigo
    and   es_codigo in (1,4)
	
	if @@rowcount =  0
		begin
			select @w_error = 101001 --NO EXISTE DATO SOLICITADO
			select @w_msg = 'NO EXISTE DATO SOLICITADO'
			goto ERROR
		end
end

if @i_operacion='G'  begin--Garantias
  if @i_cond1='1'
     select es_codigo,es_descripcion from ca_estado
  else
     select es_descripcion from ca_estado
     where es_codigo=@i_parametro
    
  if @@rowcount = 0
  begin
    select @w_error = 101001 --NO EXISTE DATO SOLICITADO
    select @w_msg = 'NO EXISTE DATO SOLICITADO'
    goto ERROR
  end
end

if @i_operacion = 'M'  --Estados manuales
   select   
   'Codigo'          =B.es_codigo,
   'Estados Posibles'=B.es_descripcion
   from     ca_estados_man,ca_estado A,ca_estado B
   where    A.es_descripcion = @i_estado_ini
   and      em_tipo_cambio = 'M'
   and      em_toperacion = @i_toperacion
   and      A.es_codigo    = em_estado_ini
   and      em_estado_fin  = B.es_codigo
   order by B.es_descripcion

if @i_operacion = 'R'  --Estados para Reajuste
begin
   select   es_descripcion
   from     ca_estado 
   where    es_procesa = 'S'
   and  es_codigo in (1,2,9)
end

if @i_operacion = 'W'
 select convert(varchar,es_codigo),
        es_descripcion 
   from ca_estado
  where es_codigo not in (select estado from @w_estados_excluidos)

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error,
	    @i_msg 	  = @w_msg
   return @w_error 
   
go
