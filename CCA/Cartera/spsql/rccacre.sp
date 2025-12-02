/************************************************************************/
/*	Archivo:		rccacre.sp				*/
/*	Stored procedure:	sp_rubro_conversion     		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto:               Cobis CARTERA                     	*/
/*	Disenado por:           Xavier Maldonado			*/
/*	Fecha de escritura:     Julio/2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa procesa operaciones de mantenimiento de los tipos	*/
/*      de datos que manejan las tablas de rubros con rangos.           */ 
/*	I: Creacion del registro de tipos de datos			*/
/*	U: Actualizacion del registro de tipos de datos			*/
/*	D: Eliminacion del registro de tipos de datos			*/
/*	S: Busqueda del registro de tipos de datos			*/
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_rubro_conversion')
   drop proc sp_rubro_conversion

go
create proc sp_rubro_conversion (
        @i_operacion		char(1),
        @i_modo			tinyint 	= null,
	@i_concepto_cre		char(10)	= null,
        @i_concepto_cca         catalogo        = null,
        @i_descripcion          descripcion     = null
)
as

declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_siguiente            int,
@w_error                int,
@w_concepto_cca	        catalogo,
@w_descripcion_cca      descripcion,
@w_concepto_cre         char(10),
@w_descripcion_cre      descripcion


select @w_sp_name = 'sp_rubro_conversion'

/** Insert **/
if @i_operacion = 'I'
begin

   /* VERIFICO QUE NO EXISTA CONCEPTO */
   if exists (select 1 from cob_cartera..ca_rubro_cca_cre
	      where ru_cca = @i_concepto_cca)
   begin
      select @w_error = 710245
      goto ERROR
   end
      
   /* INSERT A ca_rubro_cca_cre */
   begin tran

   insert into ca_rubro_cca_cre (
   ru_cca,
   ru_cre,
   ru_descripcion)
   values (
   @i_concepto_cca,
   @i_concepto_cre,
   @i_descripcion)

   if @@error != 0
   begin
      select @w_error = 710057
      goto ERROR
   end

   commit tran

end

/** Update **/

if @i_operacion = 'U'
begin

   /* VERIFICO SI EXISTE CONCEPTO */
   if not exists (select 1
                  from ca_rubro_cca_cre
	          where ru_cca = @i_concepto_cca)
   begin
      select @w_error = 710060
      goto ERROR
   end

      
   begin tran

      /* UPDATE DATOS DE TABLAS DE RUBROS */
      update	cob_cartera..ca_rubro_cca_cre set	
      ru_cca            = @i_concepto_cca,
      ru_cre            = @i_concepto_cre,
      ru_descripcion    = @i_descripcion
      where ru_cca = @i_concepto_cca

      if @@error != 0 
         begin
            select @w_error = 710062
            goto ERROR
         end

   commit tran

end


/** Search **/

if @i_operacion = 'S'
begin

    set rowcount 20
    if @i_modo = 0
    begin 
        select
        'Rubro Cartera'	            = ru_cca,
        'Rubro Credito'             = ru_cre,
        'Descripcion'               = ru_descripcion
        from	cob_cartera..ca_rubro_cca_cre
        order by ru_cca
    end

    if @i_modo = 1
    begin 
        select
        'Rubro Cartera'	            = ru_cca,
        'Rubro Credito'             = ru_cre,
        'Descripcion'               = ru_descripcion
        from	cob_cartera..ca_rubro_cca_cre
        where ru_cca > @i_concepto_cca
        order by ru_cca
        
        if @@rowcount = 0         
        begin
           select @w_error = 710060
            goto ERROR
        end
    end
    set rowcount 0

end



/** Delete **/        

if @i_operacion = 'D'
begin

   begin tran
   
   delete cob_cartera..ca_rubro_cca_cre
   where ru_cca = @i_concepto_cca

   if @@error != 0 
   begin
      select @w_error = 710063
      goto ERROR
   end
  
   commit tran 
end



/** Query **/

if @i_operacion = 'Q'
begin

    set rowcount 1
    begin 
        select
        ru_cca,
        co_descripcion,
        ru_cre,
        ru_descripcion
        from	cob_cartera..ca_rubro_cca_cre, ca_concepto
        where ru_cca = co_concepto
        and ru_cca = @i_concepto_cca
        
        if @@rowcount = 0         
        begin
           select @w_error = 710060
            goto ERROR
        end
    end
    set rowcount 0

end


return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',         @t_file = null,
@t_from  = @w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

