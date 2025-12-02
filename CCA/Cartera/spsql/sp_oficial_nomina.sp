/********************************************************************/
/*   NOMBRE LOGICO:      sp_oficial_nomina                          */
/*   NOMBRE FISICO:      sp_oficial_nomina.sp                       */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Marzo 2024                                 */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Programa que administra la nómina de oficiales para el proce-  */ 
/*   so de incentivos                                               */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA         AUTOR            RAZON                            */
/*  21-Feb-2024   K. Rodriguez     R225308 Emision Inicial          */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_oficial_nomina')
   drop proc sp_oficial_nomina
go

create proc sp_oficial_nomina
@s_user                   login,
@s_date                   datetime,
@s_term                   varchar(30),
@s_ofi                    smallint,
@s_ssn                    int,
@s_sesn                   int,
@i_operacion              char(1),           -- I: Insertar, U: Actualizar, D: Eliminar , S: Listar
@i_opcion                 tinyint,
@i_oficial                int         = null,
@i_nomina                 varchar(5)  = null,
@i_externo                char(1)     = 'N'

          
as
declare 
@w_sp_name               descripcion,
@w_error                 int,
@w_commit                char(1),
@w_secuencial_ing        int,
@w_num_condicion_abonos  int,
@w_cont                  int,
@w_opcion                tinyint,
@w_sec_ofi_nom           int


-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_oficial_nomina',
       @w_error     = 0,
	   @w_commit    = 'N'

--**** VALIDACIONES
if @i_operacion in ('I', 'U')
begin

   if not exists (select 1 
                  from cobis..cc_oficial
				  where oc_oficial = @i_oficial)
   begin
      select @w_error = 725194  -- No existe el oficial 
      goto ERROR
   end

end

if @i_operacion in ('U', 'D')
begin
	  
   select @w_sec_ofi_nom = on_sec
   from ca_oficial_nomina
   where on_oficial = @i_oficial
   and on_estado = 'A'

   if @@rowcount = 0
   begin
      select @w_error = 725313 -- Error, no existe registro activo de nomina para el oficial
      goto ERROR
   end 
   
end 

--**** OPERACIONES
if @i_operacion = 'S' -- Listar
begin

   if @i_opcion = 1
   begin
      
      select on_oficial,
	         on_nomina
	  from ca_oficial_nomina
	  where on_estado = 'A'
	  order by on_oficial asc
	  
      if @@rowcount = 0
	  begin
         select @w_error = 708192 -- No existen registros
         goto ERROR
	  end
   
   end
 	  
end

if @i_operacion = 'I'
begin
 
   if exists (select 1 
              from ca_oficial_nomina
		      where on_oficial = @i_oficial
			  and on_estado = 'A')
   begin
      select @w_error = 725314 -- Error, ya exista un registro de nómina activa para el oficial
      goto ERROR
   end
   
   if @i_externo = 'S' -- INI ATOM1
   begin
      select @w_commit = 'S'
      begin tran
   end
   
   insert into ca_oficial_nomina (
   on_user,    on_fecha_creacion, on_fecha_real,
   on_oficial, on_nomina,         on_estado) 
   values (
   @s_user,    getdate(),         getdate(), 
   @i_oficial, @i_nomina,         'A')

   if @@error <> 0
   begin
      select @w_error = 725315 -- Error al insertar registro de nómina
      goto ERROR
   end
	  
end

if @i_operacion = 'U'
begin

   if @i_externo = 'S' -- INI ATOM1
   begin
      select @w_commit = 'S'
      begin tran
   end
	  
   update ca_oficial_nomina
   set on_estado     = 'I',
       on_fecha_real = getdate()
   where on_oficial = @i_oficial
   and on_sec = @w_sec_ofi_nom
   
   if @@error <> 0
   begin
      select @w_error = 725316 -- Error al actualizar registro de nómina
      goto ERROR
   end
   
   insert into ca_oficial_nomina (
          on_user,    on_fecha_creacion, on_fecha_real,
          on_oficial, on_nomina,         on_estado) 
   select @s_user,    getdate(),         getdate(),
          on_oficial, @i_nomina,         'A'
   from ca_oficial_nomina
   where on_oficial = @i_oficial
   and on_sec = @w_sec_ofi_nom   

   if @@error <> 0
   begin
      select @w_error = 725315 -- Error al insertar registro de nómina
      goto ERROR
   end
	  
end

if @i_operacion = 'D'
begin

   if @i_externo = 'S' -- INI ATOM1
   begin
      select @w_commit = 'S'
      begin tran
   end

   update ca_oficial_nomina	  
   set on_estado     = 'I',
       on_fecha_real = getdate()
   where on_oficial = @i_oficial
   and on_sec = @w_sec_ofi_nom
   
   if @@error <> 0
   begin
      select @w_error = 725316 -- Error al actualizar registro de nómina
      goto ERROR
   end
   
end

if @i_externo = 'S' -- FIN ATOM1
   if @w_commit = 'S'
      commit tran
   
return 0

ERROR:

if @i_externo = 'S'
begin 

   if @w_commit = 'S'
      while @@trancount > 0 rollback tran -- FIN ATOM1
	  
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error
   
end

return @w_error
go
