/************************************************************************/
/*      Archivo              :     rolautcond.sp                        */
/*      Stored procedure     :     sp_rol_aut_condona                   */
/*      Base de datos        :     cob_cartera                          */
/*      Producto             :     cartera                              */
/*      Fecha de escritura   :     Diciembre-2011                       */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'                                                     */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                          PROPOSITO                                   */
/*                                                                      */
/************************************************************************/
USE cob_cartera
GO
if exists (select 1 from sysobjects where name = 'sp_rol_aut_condona')
           drop proc sp_rol_aut_condona
go
create proc sp_rol_aut_condona
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 0,
   @s_sesn                   int          = 0,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 0,
   @s_srv                    varchar (30) = null,
   @s_lsrv                   varchar (30) = null,
   @s_ofi                    smallint     = null,
   @i_secuencial             smallint     = null,
   @t_debug                  char(1)      = 'N',
   @t_file                   varchar(14)  = null,  
   @i_operacion              char(1)      ='S',
   @i_rol_condona            tinyint      =null,
   @i_rol_autor              tinyint      = null
as
declare
   @w_error                int,
   @w_sp_name              descripcion,
   @w_sec                  int,
   @w_clave1			   varchar(255),
   @w_clave2			   varchar(255),
   @w_clave3			   varchar(255)

--- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_rol_aut_condona'

if @i_operacion = 'I' or @i_operacion = 'U'
begin
    -- verificacion de repetidos
    
    if exists (   select 1
            from ca_rol_autoriza_condona
            where rac_rol_condona       = @i_rol_condona
            and   rac_rol_autoriza      = @i_rol_autor)      
    begin
    /* Relación de Rol y condonación ya ingresado*/
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 721906
        return 1 
    end
    
    if @i_rol_condona = @i_rol_autor
    begin
    /*  Rol que autoriza no puede ser igual al de condonación*/
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 721905
        return 1 
    end
    
end 

if @i_operacion = 'S' begin
      select  
              'Rol Condonador'  = rac_rol_condona,
              'Descripcion' = (select ro_descripcion from cobis..ad_rol where ro_rol = rac_rol_condona),
              'Rol Autorizador' = rac_rol_autoriza,
              'Descripcion ' = (select ro_descripcion from cobis..ad_rol where ro_rol = rac_rol_autoriza)
      from  ca_rol_autoriza_condona 
      order by rac_rol_condona, rac_rol_autoriza
end

if @i_operacion = 'Q' begin
      print 'ok'

end


if @i_operacion = 'I' begin 

   insert into ca_rol_autoriza_condona
      (rac_rol_condona, rac_rol_autoriza)
   values
      (@i_rol_condona, @i_rol_autor)
        
    if @@error <>0 begin
        select @w_error = '603059'
        goto ERROR
    end
    
    select @w_clave1 = convert(varchar(255),@i_rol_condona)
    select @w_clave2 = convert(varchar(255),@i_rol_autor)
    
    exec @w_error  = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_rol_autoriza_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end    
    
end

if @i_operacion = 'D' begin

    select @w_clave1 = convert(varchar(255),@i_rol_condona)
    select @w_clave2 = convert(varchar(255),@i_rol_autor)
    
    exec @w_error  = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_rol_autoriza_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end 

    delete  ca_rol_autoriza_condona
    where rac_rol_condona  = @i_rol_condona
    and   rac_rol_autoriza = @i_rol_autor
    if @@error <>0
    begin
       select @w_error = '710003'
       goto ERROR
    end
end

goto FIN

ERROR:

exec cobis..sp_cerror
   @t_debug  = 'N',
   @t_file   = null,
   @t_from   = @w_sp_name,
   @i_num    = @w_error

return @w_error

FIN:

return 0
go