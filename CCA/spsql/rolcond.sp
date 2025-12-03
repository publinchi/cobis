/************************************************************************/
/*      Archivo              :     rolcond.sp                           */
/*      Stored procedure     :     sp_rol_condona	                    */
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
if exists (select 1 from sysobjects where name = 'sp_rol_condona')
           drop proc sp_rol_condona
go
create proc sp_rol_condona
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
   @i_condonacion            smallint     =null,
   @i_rol                    tinyint      = null,
   @i_modo                   tinyint      = null,
   @i_condona                int          = null,
   @i_rol_busc               int          = null
as
declare
   @w_error                int,
   @w_sp_name              descripcion,
   @w_sec                  int,
   @w_clave1			   varchar(255),
   @w_clave2			   varchar(255),
   @w_clave3			   varchar(255)

--- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_rol_condona'

if @i_operacion = 'I' 
begin
    -- verificacion de repetidos
    
    if exists (   select 1
            from ca_rol_condona
            where rc_rol           = @i_rol
            and   rc_condonacion   = @i_condonacion)      
    begin
    /* Relación de Rol y condonación ya ingresado*/
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 721906
        return 1 
    end
end 

if @i_operacion = 'S' begin

   create table #rolcondona   (
   secuencial    int          identity,
   rol           tinyint      null,
   descrip_rol   descripcion  null,
   condonacion   smallint     null,
   descrip_cond  varchar(100)  null
   )
   
   if @i_rol_busc is null and @i_condona is null
   begin
   insert into #rolcondona
   select  
            'Rol'             = rc_rol,
            'Descripcion Rol' = (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol),
            'Condonacion'     = rc_condonacion,
            'Descripcion Condonacion' =    ( select (select top 1 es_descripcion from cob_cartera..ca_estado
                                         where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
                    (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
              from  ca_param_condona p
              where pc_codigo = rc_condonacion)
   from  ca_rol_condona	
   order by rc_condonacion
   end

   if @i_rol_busc is null or @i_condona is null
   begin
   insert into #rolcondona
   select  
            'Rol'             = rc_rol,
            'Descripcion Rol' = (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol),
            'Condonacion'     = rc_condonacion,
            'Descripcion Condonacion' =    ( select (select top 1 es_descripcion from cob_cartera..ca_estado
                                         where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
                    (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
              from  ca_param_condona p
              where pc_codigo = rc_condonacion)--'Condonacion numero ' + cast(rc_condonacion as varchar)
   from  ca_rol_condona	
   where rc_rol = @i_rol_busc
   or rc_condonacion = @i_condona
   order by rc_condonacion
   end
   else
   begin
   insert into #rolcondona
   select  
            'Rol'             = rc_rol,
            'Descripcion Rol' = (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol),
            'Condonacion'     = rc_condonacion,
            'Descripcion Condonacion' =    ( select (select top 1 es_descripcion from cob_cartera..ca_estado
                                         where  es_codigo = p.pc_estado) + ' - ' + cast(pc_banca as varchar) + ' - '+
                    (select top 1 b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                         where  a.tabla = 'cr_rubro_condonable'
                                         and    a.codigo = b.tabla
                                         and    b.codigo = p.pc_rubro)+ ' - '+
                    cast(pc_mora_inicial as varchar)+' - '+
                    cast(pc_mora_final as varchar)+' - '+
                    cast(isnull(pc_ano_castigo,0) as varchar)+' - '+cast(pc_valor_maximo as varchar)
              from  ca_param_condona p
              where pc_codigo = rc_condonacion)--'Condonacion numero ' + cast(rc_condonacion as varchar)
   from  ca_rol_condona	
   where rc_rol = @i_rol_busc
   and rc_condonacion = @i_condona
   order by rc_condonacion
   end

   set rowcount 20
   if @i_secuencial = 0
   begin
        select  
            'I'               = secuencial,
            'Rol'             = rol,
            'Descripcion Rol' = descrip_rol,
            'Condonacion'     = condonacion,
            'Descripcion Condonacion' = descrip_cond
        from  #rolcondona	
        order by secuencial

        set rowcount 0
   end
   else
   begin 
        select  
            'I'               = secuencial,
            'Rol'             = rol,
            'Descripcion Rol' = descrip_rol,
            'Condonacion'     = condonacion,
            'Descripcion Condonacion' = descrip_cond
        from  #rolcondona
        where secuencial > @i_secuencial	
        order by secuencial

        set rowcount 0
   end

end
if @i_operacion = 'A'
begin
        set rowcount 20
        if @i_modo = 0
        begin
           select distinct
           'Rol'         = rc_rol,
           'Descripcion' = (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol)
           from ca_rol_condona            
           order by rc_rol ASC  
           
           set rowcount 0
        end
        if @i_modo = 1
        begin
          select distinct
           'Rol'         = rc_rol,
           'Descripcion' = (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol)
           from ca_rol_condona 
           where rc_rol > @i_rol
           order by rc_rol ASC  

          set rowcount 0
        end        
end

if @i_operacion = 'I' begin 

   insert into ca_rol_condona
      (rc_rol, rc_condonacion)
   values
      (@i_rol, @i_condonacion)
        
    if @@error <>0 begin
        select @w_error = '603059'
        goto ERROR
    end
    
    select @w_clave1 = convert(varchar(255),@i_rol)
    select @w_clave2 = convert(varchar(255),@i_condonacion)
    
        exec @w_error  = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_rol_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end    
    
end

if @i_operacion = 'D' begin

    select @w_clave1 = convert(varchar(255),@i_rol)
    select @w_clave2 = convert(varchar(255),@i_condonacion)
    
    exec @w_error  = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_rol_condona',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2,
        @i_clave3  = @i_operacion
   
    if @w_error <> 0
    begin
      goto ERROR
    end 

    delete  ca_rol_condona
    where   rc_rol = @i_rol
    and     rc_condonacion = @i_condonacion
    if @@error <>0
    begin
       select @w_error = '710003'
       goto ERROR
    end
end

/**** VALUE ****/
/***************/
if @i_operacion = 'V'
begin
        select rc_rol,   
               (select ro_descripcion from cobis..ad_rol where ro_rol = rc_rol)
        from  ca_rol_condona
        where rc_rol = @i_rol
        
        if @@rowcount = 0
        begin
          -- 'NO EXISTE DATO SOLICITADO '
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file        = @t_file,
          @t_from        = @w_sp_name,
          @i_num         = 2101005
          return 1
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