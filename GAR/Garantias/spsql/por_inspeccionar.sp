/*************************************************************************/
/*   Archivo:              por_inspeccionar.sp                           */
/*   Stored procedure:     sp_por_inspeccionar                           */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion                    */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_por_inspeccionar') IS NOT NULL
    DROP PROCEDURE dbo.sp_por_inspeccionar
go
create proc sp_por_inspeccionar (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo               descripcion  = null,
   @i_tipo_cust          descripcion  = null,
   @i_custodia           int  = null,
   @i_status             char(  1)  = null,
   @i_fecha_ant          datetime  = null,
   @i_inspector_ant      tinyint  = null,
   @i_estado_ant         catalogo  = null,
   @i_inspector_asig     tinyint  = null,
   @i_fecha_asig         datetime  = null,
   @i_formato_fecha      int   = null,
   @i_inspector		 tinyint   = null,
   @i_fecha_ini          datetime  = null,
   @i_fecha_insp         datetime  = null,
   @i_fecha_fin		 datetime  = null,
   @i_codigo_externo     varchar(64) = null,
   @i_oficial            smallint         = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo               varchar(64),
   @w_custodia           int,
   @w_status             char(1),
   @w_inspeccionado      char(1),
   @w_fecha_ant          datetime,
   @w_inspector_ant      tinyint,
   @w_estado_ant         catalogo,
   @w_inspector_asig     tinyint,
   @w_fecha_asig         datetime,
   @w_fecha_inspec       datetime,
   @w_cliente_principal  int,
   @w_riesgos            money, 
   @w_mes_actual         tinyint, 
   @w_nro_inspecciones   tinyint, 
   @w_intervalo          tinyint,
   @w_estado             catalogo,
   @w_fecha_insp         datetime,
   @w_gar_personal       descripcion,
   @w_scu                descripcion,
   @w_cont               tinyint, /* Flag para saber si existen prendas */
   @w_codigo_externo     varchar(64),
   @w_estado_gar         char(1),
   @w_fecha_prox_insp    datetime,
   @w_oficial            int


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_por_inspeccionar'
select @w_gar_personal = pa_char + '%'       
  from cobis..cl_parametro
 where pa_producto = 'GAR'
   and pa_nemonico = 'GARGPE' 

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19160 and @i_operacion = 'I') or
   (@t_trn <> 19161 and @i_operacion = 'U') or
   (@t_trn <> 19162 and @i_operacion = 'D') or
   (@t_trn <> 19163 and @i_operacion = 'V') or
   (@t_trn <> 19164 and @i_operacion = 'S') or
   (@t_trn <> 19165 and @i_operacion = 'Q') or
   (@t_trn <> 19166 and @i_operacion = 'A') or
   (@t_trn <> 19167 and @i_operacion = 'Z')
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end


/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_filial = pi_filial,
         @w_sucursal = pi_sucursal,
         @w_tipo = pi_tipo,
         @w_custodia = pi_custodia,
         @w_fecha_ant = pi_fecha_ant,
         @w_inspector_ant = pi_inspector_ant,
         @w_estado_ant = pi_estado_ant,
         @w_inspector_asig = pi_inspector_asig,
         @w_fecha_asig = pi_fecha_asig,
         @w_codigo_externo = pi_codigo_externo,
         @w_inspeccionado  = pi_inspeccionado,
         @w_fecha_inspec   = pi_fecha_insp
    from cob_custodia..cu_por_inspeccionar
    where pi_filial = @i_filial 
      and pi_sucursal = @i_sucursal 
      and pi_tipo   = @i_tipo   
      and pi_custodia = @i_custodia 
      and pi_inspeccionado  = 'N'
         

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
     if  @i_filial = NULL or 
         @i_sucursal = NULL or 
         @i_tipo = NULL or 
         @i_custodia = NULL 
     begin
         /* Campos NOT NULL con valores nulos */
          exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1901001
          return 1 
     end
end


/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
    if @w_existe = 1
    begin
        /* Registro ya existe */
        exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file, 
          @t_from  = @w_sp_name,
          @i_num   = 1901002
        return 1 
    end

    -- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

    select @w_oficial = cg_oficial
    from cu_cliente_garantia
    where cg_codigo_externo = @w_codigo_externo

    if @w_oficial <> @i_oficial and @i_oficial is not null
    begin
        /* Oficial no corresponde */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907018
        return 1      
    end

    select @w_estado_gar = cu_estado
    from cu_custodia
    where cu_codigo_externo = @w_codigo_externo   
   
    if @w_estado_gar = 'C' --Cancelado
    begin 
        /* No puede inspeccionar garantias canceladas */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905010
        return 1 
    end 
    
    begin tran
         insert into cu_por_inspeccionar(
              pi_filial,
              pi_sucursal,
              pi_tipo,
              pi_custodia,
              pi_fecha_ant,
              pi_inspector_ant,
              pi_estado_ant,
              pi_inspector_asig,
              pi_fecha_asig,
              pi_riesgos,
              pi_codigo_externo,
              pi_inspeccionado)
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo,
              @i_custodia,
              @i_fecha_ant,
              @i_inspector_ant,
              @i_estado_ant,
              @i_inspector_asig,
              @s_date,
              isnull(@w_riesgos,0),
              @w_codigo_externo,
              'N')

         if @@error <> 0 
         begin
             /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end
         

         update cu_custodia
         set cu_fecha_prox_insp = @i_fecha_ini
         where cu_codigo_externo = @w_codigo_externo  

    commit tran 
    return 0
end


/* Actualizacion del registro */
/******************************/
if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
        /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    begin tran
         -- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         update cob_custodia..cu_por_inspeccionar
         set pi_inspector_asig = @i_inspector_asig,
             pi_fecha_asig     = @s_date
         where pi_codigo_externo = @w_codigo_externo
           and pi_inspeccionado  = 'N'
           and pi_fecha_insp     is null 

         if @@error <> 0 
         begin
             /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

    commit tran
    return 0
end


/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
        /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

    /***** Integridad Referencial *****/
    /*****                        *****/
    begin tran
         delete cob_custodia..cu_por_inspeccionar
         where pi_filial = @i_filial 
           and pi_sucursal = @i_sucursal 
           and pi_tipo = @i_tipo 
           and pi_custodia = @i_custodia

         if @@error <> 0
         begin
             /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

    commit tran
    return 0
end


/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
    if @w_existe = 1
         select 
              @w_filial,
              @w_sucursal,
              @w_tipo,
              @w_custodia,
              @w_fecha_ant,
              @w_inspector_ant,
              @w_estado_ant,
              @w_inspector_asig,
              @w_fecha_asig,
              @w_inspeccionado
    else
    begin
        /*Registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005
        return 1 
    end
    return 0
end


/* Operacion de Busqueda con cursor  */
if @i_operacion = 'Z'
begin
      -- DETERMINAR LAS GARANTIAS A INSPECCIONARSE
--      declare busqueda insensitive cursor for --/ HHO Mayo/2012    Migracion SYBASE 15
      declare busqueda cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
      select cu_tipo,cu_custodia,cu_codigo_externo,cu_intervalo,cu_fecha_insp, 
             cu_nro_inspecciones,cu_fecha_prox_insp
      from cu_custodia,cu_tipo_custodia,cu_cliente_garantia
      where cu_filial   =  @i_filial
        and cu_sucursal =  @i_sucursal
        and (cu_tipo = @i_tipo_cust or @i_tipo_cust is null)
        and cu_garante  is null
        and cu_inspeccionar = 'S'    -- A inspeccionar
        and cu_periodicidad <> 'N'   -- Periodicidad Ninguna
        and cu_estado       not in ('A','C')   -- No incluir las canceladas
        and cu_tipo         = tc_tipo
        and tc_contabilizar = 'S'    -- Solo incluir las contabilizables 
        and cu_codigo_externo  = cg_codigo_externo
        and cg_principal       = 'S' 
        and (cg_oficial = @i_oficial or @i_oficial is null)
        and (cu_fecha_prox_insp between @i_fecha_ini and @i_fecha_fin)
      open busqueda
      fetch busqueda into @w_tipo,@w_custodia,@w_codigo_externo,
                          @w_intervalo,@w_fecha_insp,@w_nro_inspecciones,
                          @w_fecha_prox_insp  
                          
      if (@@FETCH_STATUS = -1)    --  No existen garantias
      begin
         close busqueda
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901003
         return 1 -- No existen registros
      end

      while (@@FETCH_STATUS = 0)  -- Lazo de busqueda
      begin
         if exists (select * from cu_por_inspeccionar
                    where pi_codigo_externo = @w_codigo_externo
                      and pi_inspeccionado  = 'N')
         select @w_codigo_externo = @w_codigo_externo -- Ya existe
         else 
         -- NO INCLUIR GARANTIAS SIN RIESGOS NI GARANTES PERSONALES
         begin                                      -- and @w_riesgos <> 0
                if @w_tipo <> @w_gar_personal 
                begin
                select @w_inspector_ant   = null,
                        @w_fecha_ant       = null,
                        @w_estado_ant      = null,
                        @w_fecha_asig      = null,
                        @w_fecha_insp      = null,
                        @w_fecha_prox_insp = null

                select @w_inspector_ant = in_inspector,
                        @w_fecha_ant     = in_fecha_insp,
                        @w_estado_ant    = in_estado   
                from   cu_inspeccion  -- DATOS DE LA ULTIMA INSPECCION
                where  in_codigo_externo = @w_codigo_externo
                        and  in_fecha_insp in (select max(in_fecha_insp)
                                   from  cu_inspeccion
         			  where  in_codigo_externo = @w_codigo_externo)

                /*exec @w_return = sp_riesgos
                @s_date           = @s_date,
                @t_trn            = 19445,
                @i_operacion      = 'Q',
                @i_codigo_externo = @w_codigo_externo,
                @o_riesgos        = @w_riesgos out 

                if @w_return <> 0
                begin
                print "No puede sacar los riesgos"
                return 3  -- No puede sacar riesgos 
                end */

                begin tran
            
                insert into cu_por_inspeccionar values 
                (@i_filial,@i_sucursal,@w_tipo,@w_custodia,@w_fecha_ant,
                @w_inspector_ant,@w_estado_ant,null,
                @w_fecha_prox_insp,null,@w_codigo_externo,'N',null,null,null)

                commit tran
                end
         end
 
         fetch busqueda into @w_tipo,@w_custodia,@w_codigo_externo,
                             @w_intervalo,@w_fecha_insp,@w_nro_inspecciones,
                             @w_fecha_prox_insp

      end   --  FIN DEL WHILE

      if (@@FETCH_STATUS = -2)  -- ERROR DEL CURSOR
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1909001 
         return 1 
      end
      close busqueda
      deallocate busqueda
      set rowcount 20
      select "GARANTIA"=pi_custodia,
             "TIPO"=pi_tipo,
             "RIESGOS" = pi_riesgos,
             "FECHA ANT"=convert(char(10),pi_fecha_ant,@i_formato_fecha),
             "INSP.ANT"=isnull(convert(varchar(20),pi_inspector_ant),''), 
             "ESTADO ANT"=pi_estado_ant, 
             "CIUDAD"=cu_ciudad_prenda,
             "INSPECTOR"=isnull(convert(varchar(20),pi_inspector_asig),'')
      from cu_por_inspeccionar,cu_custodia,cu_cliente_garantia
      where pi_filial    = @i_filial
      and   pi_sucursal  = @i_sucursal
      and   (pi_tipo     = @i_tipo_cust or @i_tipo_cust is null)
      --and   pi_inspeccionado = 'N'   -- No han sido inspeccionadas
      and   (cg_oficial   = @i_oficial or @i_oficial is null)
      and   pi_codigo_externo = cg_codigo_externo
      and   cg_principal       = 'S' 
      and   (cu_fecha_prox_insp between @i_fecha_ini and @i_fecha_fin)
      and   pi_codigo_externo = cu_codigo_externo
      and   cu_periodicidad <> 'N'   -- Periodicidad Ninguna
      and   cu_estado       not in ('A','C')   -- No incluir las canceladas
      and   ((pi_tipo > @i_tipo_cust or 
            (pi_tipo = @i_tipo_cust and pi_custodia > @i_custodia)) or
             @i_custodia is null )
      order by pi_tipo,pi_custodia 

      if @@rowcount = 0
      begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1901003
            return 1 -- No existen registros
      end
end


if @i_operacion = 'S' /* Busca las prendas a inspeccionar para el reporte */
begin
   set rowcount 20
   select distinct 'INSPECTOR' = is_inspector,
          ' ' = is_nombre,
          'GARANTIA'=pi_custodia,
          'TIPO'=pi_tipo,
          'DESCRIPCION' = tc_descripcion,
          'DIRECCION'=substring(isnull(cu_direccion_prenda,''),1,20),
          'TELEFONO'=isnull(cu_telefono_prenda,''),
          'OFICIAL'= cg_oficial,
          'CLIENTE'= cg_nombre
 from cu_custodia,cu_por_inspeccionar,cu_inspector,
      cu_cliente_garantia,cu_tipo_custodia
   where pi_filial         = @i_filial
     and pi_sucursal       = @i_sucursal
     and (pi_tipo          = @i_tipo_cust or @i_tipo_cust is null)
     and cu_codigo_externo = pi_codigo_externo
     and cg_codigo_externo = cu_codigo_externo
     and (cg_oficial        = @i_oficial or @i_oficial is null)
     and cg_principal      = 'S' 
     and is_inspector      = pi_inspector_asig
     and pi_inspeccionado  = 'N'  -- No inspeccionada
     and (pi_inspector_asig = @i_inspector or @i_inspector is null)
     and ((pi_inspector_asig > @i_inspector or
          (pi_inspector_asig = @i_inspector and pi_tipo > @i_tipo) or 
          (pi_inspector_asig = @i_inspector and
           pi_tipo = @i_tipo and pi_custodia > @i_custodia)) 
           or @i_custodia is null)
     and cu_inspeccionar   = 'S'
     and cu_periodicidad  <> 'N'
     and tc_tipo = pi_tipo
    order by is_inspector,pi_tipo,pi_custodia

    if @@rowcount = 0 
       return 1 
   return 0
end
go