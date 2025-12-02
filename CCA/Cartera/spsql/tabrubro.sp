/************************************************************************/
/*	Archivo:		tabrubro.sp				*/
/*	Stored procedure:	sp_tabla_rubro				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto:               Cobis CARTERA                     	*/
/*	Disenado por:           Patricio Narvaez			*/
/*	Fecha de escritura:     25-Jul-1997				*/
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

if exists (select 1 from sysobjects where name = 'sp_tabla_rubro')
   drop proc sp_tabla_rubro

go
create proc sp_tabla_rubro (
        @i_operacion		char(1),
        @i_modo			tinyint 	= null,
	@i_concepto		catalogo	= null,
        @i_titulo1              catalogo        = null,
        @i_titulo2              catalogo        = null,
        @i_tipodato1            char(2)         = null,
        @i_titulo3              catalogo        = null,
        @i_tipodato2            char(2)         = null

)
as

declare 
@w_sp_name		varchar(32),
@w_return		int,
@w_siguiente            int,
@w_tipodato1            char(1),
@w_tipodato2            char(1),
@w_error                int

select @w_sp_name = 'sp_tabla_rubro'

/** Insert **/
if @i_operacion = 'I'
begin

   /* VERIFICO QUE NO EXISTA CONCEPTO */
   if exists (select 1 from cob_cartera..ca_campos_tablas_rubros
	      where ct_concepto = @i_concepto)
   begin
      select @w_error = 710058
      goto ERROR
   end
      
   /* INSERT A CA_CAMPOS_TABLAS_RUBROS */
   begin tran

   insert into ca_campos_tablas_rubros (
   ct_concepto,
   ct_titulo1,
   ct_titulo2,
   ct_tipodato1,
   ct_tipodato2,
   ct_titulo3)
   values (
   @i_concepto,
   @i_titulo1,
   @i_titulo2,
   @i_tipodato1,
   @i_tipodato2,
   @i_titulo3)

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
                  from ca_campos_tablas_rubros
	          where ct_concepto = @i_concepto)
   begin
      select @w_error = 710060
      goto ERROR
   end

   select   
   @w_tipodato1 = rtrim(ct_tipodato1),
   @w_tipodato2 = rtrim(ct_tipodato2)
   from     ca_campos_tablas_rubros
   where    ct_concepto = @i_concepto 
      
   if (@i_tipodato1 <> @w_tipodato1) or (@i_tipodato2 <> @w_tipodato2) 
   begin
      if @i_tipodato2 is null
      begin
         if exists(select 1
                  from ca_tablas_un_rango
	          where tur_concepto = @i_concepto)
         begin
            select @w_error = 710061
            goto ERROR
         end 
      end
      else
      begin
         if exists(select 1
                  from ca_tablas_dos_rangos
	          where tdr_concepto = @i_concepto)
         begin 
            select @w_error = 710061
            goto ERROR
         end 
      end
   end

   begin tran

      /* UPDATE DATOS DE TABLAS DE RUBROS */
      update	cob_cartera..ca_campos_tablas_rubros set	
      ct_titulo1            = @i_titulo1,
      ct_titulo2            = @i_titulo2,
      ct_tipodato1          = @i_tipodato1,
      ct_tipodato2          = @i_tipodato2,
      ct_titulo3            = @i_titulo3
      where	ct_concepto = @i_concepto

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
        'Rubro'	                = ct_concepto,
        'Titulo 1'               = ct_titulo1,
        'Titulo 2'               = ct_titulo2,
        'Tipo Dato1'            = ct_tipodato1,
        'Tipo Dato2'            = ct_tipodato2,
        'Titulo 3'               = ct_titulo3        
        from	cob_cartera..ca_campos_tablas_rubros
        order by ct_concepto

    end
    if @i_modo = 1
    begin
        select
        'Rubro'	                 = ct_concepto,
        'Titulo 1'               = ct_titulo1,
        'Titulo 2'               = ct_titulo2,
        'Tipo Dato1'             = ct_tipodato1,
        'Tipo Dato2'             = ct_tipodato2,
        'Titulo 3'               = ct_titulo3
        from	cob_cartera..ca_campos_tablas_rubros
        where ct_concepto  = @i_concepto
        order by ct_concepto
        
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
   if @i_modo = 0
   begin 
      if exists(select 1
                  from ca_tablas_un_rango
	          where tur_concepto = @i_concepto)
      begin
         select @w_error = 710061
         goto ERROR
      end 
   end
   else
   begin
      if exists(select 1
                  from ca_tablas_dos_rangos
	          where tdr_concepto = @i_concepto)
      begin 
         select @w_error = 710061
         goto ERROR
      end 
   end

   begin tran
   
   delete cob_cartera..ca_campos_tablas_rubros
   where ct_concepto = @i_concepto

   if @@error != 0 
   begin
      select @w_error = 710063
      goto ERROR
   end
  
   commit tran 
   

end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',         @t_file = null,
@t_from  = @w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

