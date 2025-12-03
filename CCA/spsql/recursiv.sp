/************************************************************************/
/*	Archivo: 		recursiv.sp				*/
/*	Stored procedure: 	sp_recursivo    			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	28/Ene./1998				*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Consulta de los datos de una operacion 	                 	*/
/************************************************************************/

use cob_cartera
go
 
   create table  #ca_depende (
   de_sec       int,
   de_id	int,
   de_name	varchar(255)
   )


if exists (select 1 from sysobjects where name = 'sp_recursivo')
   drop proc sp_recursivo
go



create proc sp_recursivo (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @i_id_padre          int         = null,
   @i_id                int         = null,
   @i_name              varchar(255)= null,
   @i_ntab              int         = null,
   @o_salir             int          out
  
)

as
declare	@w_sp_name	varchar(32),
        @w_tab          char(1),
        @w_ntab 	int,
        @w_name_dep	varchar(255),
	@w_id           int,
        @w_n            int,
 	@w_filas        int,
        @w_c            int,
        @w_recursivo    varchar(15) 

/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_recursivo'


select @w_tab = '	',
       @w_recursivo =''

set rowcount 1

select 
@w_name_dep = a.name,
@w_id	    = a.id
from sysobjects a, sysdepends b
where b.id   = @i_id
and   a.type = 'P'
and   a.id   = b.depid
order by a.id

if @@rowcount <> 0 begin
   select @w_id = 0   

   while 1 = 1 begin

      set rowcount 1

      select 
      @w_name_dep = a.name,
      @w_id	    = a.id
      from sysobjects a, sysdepends b
      where b.id   =  @i_id
      and   a.type = 'P'
      and   a.id   = b.depid
      and   a.id   >  @w_id
      order by a.id
    
      if @@rowcount = 0 break

      if @w_id = @i_id begin
          select @w_recursivo = '(Recursivo)'
          break
      end 

      select  @w_ntab 	= @i_ntab + 1

      exec sp_recursivo
      @i_id_padre = @i_id_padre,
      @i_id	  = @w_id,
      @i_name     = @w_name_dep,
      @i_ntab 	  = @w_ntab,
      @o_salir	  = @o_salir

   end ---END WHILE 1=1
   
end

select @o_salir = 0


if  @o_salir = 0
begin    
   select @w_n = 1,
          @w_name_dep='' 
   
   while @w_n<= @i_ntab
   begin
       select  
       @w_name_dep = @w_name_dep + @w_tab,
       @w_n = @w_n + 1         
   end
   
   select @w_name_dep = @w_name_dep + @i_name + @w_recursivo

   select @w_c = max(de_sec)
   from   #ca_depende

   if @w_c is not null
      select @w_c = @w_c +1
   else
      select @w_c= 1

   insert into #ca_depende
   values (@w_c, @i_id_padre, @w_name_dep)

end   
  
 return 0
go


