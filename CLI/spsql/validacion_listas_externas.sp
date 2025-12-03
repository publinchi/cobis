/***********************************************************************/
/*  Archivo:                validacion_listas_externas.sp              */
/*  Stored procedure:       sp_validacion_listas_externas              */
/*  Base de datos:          cobis                                      */
/*  Producto:               Clientes                                   */
/*  Disenado por:           JME                                        */
/*  Fecha de escritura:     30-Abril-19                                */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad       */
/*  de COBISCorp.                                                      */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como   */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus   */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.  */
/*  Este programa esta protegido por la ley de   derechos de autor     */
/*  y por las    convenciones  internacionales   de  propiedad inte-   */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir       */
/*  penalmente a los autores de cualquier   infraccion.                */
/***********************************************************************/
/*                             PROPOSITO                               */
/*  Este procedimiento permite hacer la validación de clientes en      */
/*  listas negras y posteriormente consultarlas por el oficial de      */
/*  cumplimiento desde la funcionalidad del módulo de Clientes.        */
/***********************************************************************/
/*                            MODIFICACIONES                           */
/*  FECHA           AUTOR     RAZON                                    */
/*  30/04/19        JME       Emision Inicial                          */
/*  28/05/20        MBA       Actualización del archivo del sp         */
/*  01/06/20        MBA       Se agrega UPPER al pe_curp oper T        */
/*  04/06/20        IRO       Ajustes Personas Morales y optimización  */
/*  11/06/20        MBA       Estandarizacion sp y seguridades         */
/*  26/08/20        AHU       Agregando variables de Sesión            */
/*  15/12/20        MGB       Cambio translate por funcion cobis       */
/*  15/12/20        MGB       Validacion de fechas en consulta         */
/*  13/01/21        MGB       Ajuste filtro fechas consulta de listas  */
/*  14/01/21        MGB       Ajuste compatibilidad con mysql          */
/***********************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO


if exists (select * 
             from sysobjects
            where type = 'P'
              and name = 'sp_validacion_listas_externas')
  drop proc sp_validacion_listas_externas
go

create procedure sp_validacion_listas_externas (
       @t_show_version          bit                 = 0,
       @t_trn                   int                 = null,
       @s_date                  datetime            = null,
       @s_user                  login               = 'BATCH',
       @s_ssn                   int                 = null,
       @s_sesn                  int                 = null,
       @s_term                  varchar(32)         = null,
       @s_srv                   varchar(30)         = null,
       @s_lsrv                  varchar(30)         = null,
       @s_rol                   smallint            = null,
       @s_ofi                   smallint            = null,
       @s_culture               varchar(10)         = null,
       @s_org                   char(1)             = null,
       @i_operacion             char(1)             = null,         
       @i_ente                  int                 = null,
       @i_rol                   varchar(11)         = null,
       @i_producto              int                 = null,
       @i_cuenta                varchar(40)         = null,
       @i_proceso               int                 = null,
       @i_observaciones         varchar(1000)       = null,
       @i_acciones              varchar(1000)       = null,
       @i_lista_negra           char(2)             = null,
       @i_lista_pep             char(2)             = null,
       @i_lista_pr              char(2)             = null,
       @t_debug                 char(1)             = 'N',
       @t_file                  varchar(10)         = null,
       @i_fecha_desde           datetime            = null,
       @i_fecha_hasta           datetime            = null,
       @i_tiene_observacion     char(1)             = null,
       @i_fecha                 datetime            = null,
       @i_param1                datetime            = null,     
       @i_param2                char(1)             = null  --OPERACION = T necesaria para procesos batch LCH
)
as
declare @w_transaccion          int,
        @w_sp_name              varchar(32),
		@w_sp_msg               varchar(132),
        @w_codigo               int,
        @w_error                int,
        @w_return               int,
        @w_rol                  varchar(11),
        @w_producto             int,
        @w_cuenta               varchar(40),
        @w_proceso              int,
        @w_observaciones        varchar(1000),
        @w_acciones             varchar(1000),
        @w_lista_negra          char(2),
        @w_lista_pep            char(2),
        @w_lista_pr             char(2),
        @w_existe_reg           int ,
        @w_subtipo              char(1),
        @w_nombre               varchar(64),
        @w_p_apellido           varchar(16),
        @w_s_apellido           varchar(16),
        @w_ced_ruc              varchar(30),
        @w_fecha_nac            datetime,
        @w_negras               int,
        @w_pep                  int,
        @w_relacionadas         int,
        @w_ente                 int,
        @w_registros_totales    int,   --operacion T
        @w_registros_procesados int,
        @w_trn                  int


/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_validacion_listas_externas'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/ 

/*LCH: Si @t_trn viene vacio, entonces procedemos a seleccionarlo de forma interna*/
if @t_trn is null or @t_trn = 0
begin 
  select @w_trn = 172027
end 
else
begin 
  select @w_trn = @t_trn
end

-- VALIDACION DE TRANSACCIONES
if (@w_trn <> 172027)
begin
   exec sp_cerror
    @t_debug  = @t_debug,
    @t_file   = @t_file,
    @t_from   = @w_sp_name,
    @i_num    = 1720075                  
    --NO CORRESPONDE CODIGO DE TRANSACCION
   return 1720075
end

 --INSERT
if @i_operacion in ('I', 'U')
  begin
    if not exists (select 1
                     from cobis..cl_ente
                    where en_ente = @i_ente)
      begin
        --NO EXISTE ENTE
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720178
        return 1
      end
  
    if not exists (select 1
                     from cobis..cl_producto
                    where pd_producto = @i_producto)
      begin
        --NO EXISTE PRODUCTO
        exec cobis..sp_cerror
           @t_debug  = @t_debug,
           @t_file   = @t_file,
           @t_from   = @w_sp_name,
           @i_num    = 1720179
        return 1
      end
  
    if (@s_user is null)
      begin
         exec cobis..sp_cerror
              @t_debug  = @t_debug,
              @t_file   = @t_file,
              @t_from   = @w_sp_name,
              @i_num    = 1720180
         return 1720180
      end

    if (@i_rol is null)
      begin
        --NO EXISTE ROL NULO
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720181
        return 1720181
      end
  
    if (len(@i_lista_negra) > 1 or len(@i_lista_pep) > 1 or len(@i_lista_pr) > 1)
      begin
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720182
        return 1720182
      end
  
   if (len(@i_rol) > 10)
     begin
       exec cobis..sp_cerror
            @t_debug  = @t_debug,
            @t_file   = @t_file,
            @t_from   = @w_sp_name,
            @i_num    = 1720183
       return 1720183
     end
  end

if (@i_operacion = 'I')
  begin
    insert into cobis..cl_validacion_listas_externas
           (rle_ente,                     rle_rol,                      rle_producto,                 rle_cuenta,
            rle_fecha_validacion,         rle_proceso,                  rle_lista_negra,              rle_lista_pep,
            rle_lista_pr,                 rle_observaciones,            rle_acciones,                 rle_usuario,
            rle_fecha_observacion)
    values (@i_ente,                      @i_rol,                       @i_producto,                  @i_cuenta,
            @s_date,                      @i_proceso,                   @i_lista_negra,               @i_lista_pep,
            @i_lista_pr,                  @i_observaciones,             @i_acciones,                  @s_user,
            @s_date)
    if (@@error <> 0)
      begin
        --ERROR EN CREACION DE VALIDACION
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720184
        return 1720184
      end
  end

if (@i_operacion = 'U')
  begin
    if (@i_lista_negra = 'fa')
      begin  
        select @i_lista_negra = null
      end 

    if (@i_lista_pep = 'fa')
      begin
        select @i_lista_pep = null
      end 
    
    if (@i_lista_pr = 'fa')
      begin
        select @i_lista_pr = null
      end

    select @w_existe_reg  = count(*)
      from cl_validacion_listas_externas
     where rle_ente       = @i_ente
       and rle_producto   = @i_producto
       and rle_cuenta     = @i_cuenta
       and rle_proceso    = @i_proceso
       and rle_rol        = @i_rol
   
    if (@w_existe_reg = 0)
      begin
        exec cobis..sp_cerror
           @t_debug  = @t_debug,
           @t_file   = @t_file,
           @t_from   = @w_sp_name,
           @i_num    = 1720019
        return 1720019
      end

    update cl_validacion_listas_externas
       set rle_observaciones        = Coalesce(@i_observaciones, rle_observaciones),
           rle_acciones             = Coalesce(@i_acciones, rle_acciones),
           rle_usuario              = Coalesce(@s_user, rle_usuario ),
           rle_fecha_observacion    = Coalesce( @s_date, rle_fecha_observacion)
    where rle_ente                  = @i_ente
      and rle_producto              = @i_producto
      and rle_cuenta                = @i_cuenta
      and rle_proceso               = @i_proceso
      and rle_rol                   = @i_rol
    if (@@error <> 0)
      begin
        --ERROR EN CREACION DE VALIDACION
        exec cobis..sp_cerror
           @t_debug   = @t_debug,
           @t_file    = @t_file,
           @t_from    = @w_sp_name,
           @i_num     = 1720184
        return 1720184
      end
   end
 
if (@i_operacion = 'S')
  begin
    if (@i_fecha_desde is not null and @i_fecha_hasta is not null and @i_tiene_observacion is not null)
      begin
        if (@i_tiene_observacion = 'T')
          begin
            select 'FECHA' 		   = rle_fecha_validacion,
                   'CLIENTE' 	   = rle_ente,
                   'NOMBRE' 	   = isnull(en_nomlar,en_nombre),
                   'PRODUCTO' 	   = pd_descripcion,
                   'CUENTA' 	   = rle_cuenta,
                   'LISTA NEGRA'   = rle_lista_negra,
                   'LISTA PEP' 	   = rle_lista_pep,
                   'LISTA PR' 	   = rle_lista_pr,
                   'COD PRODUCTO'  = rle_producto,
                   'NUM PROCESO'   = rle_proceso,
                   'ID ROL' 	   = rle_rol,
                   'USUARIO' 	   = rle_usuario,
                   'ACCIONES' 	   = rle_acciones,
                   'OBSERVACIONES' = rle_observaciones
              from cobis..cl_validacion_listas_externas vle, 
                   cobis..cl_ente,
                   cobis..cl_producto
             where rle_ente                           = en_ente
               and rle_producto                       = pd_producto
               and cast(rle_fecha_validacion as date) between CAST(@i_fecha_desde as date) and CAST(@i_fecha_hasta as date)
               and rle_producto                       = isnull(@i_producto,rle_producto)
               and rle_cuenta                         = isnull(@i_cuenta,rle_cuenta)
               and rle_ente                           = isnull(@i_ente,rle_ente)
               and (rle_lista_negra                   is not null
                or  rle_lista_pep                     is not null
                or  rle_lista_pr                      is not null)
          order by rle_ente asc
            if (@@rowcount = 0)
              begin
                --NO EXISTEN REGISTROS
                exec sp_cerror
                     @t_debug      = @t_debug,
                     @t_file       = @t_file,
                     @t_from       = @w_sp_name,
                     @i_num        = 1720081
                return 1720081
              end

            return 0
          end
        if (@i_tiene_observacion = 'S')
          begin
            select 'FECHA' 		   = rle_fecha_validacion,
                   'CLIENTE' 	   = rle_ente,
                   'NOMBRE' 	   = isnull(en_nomlar,en_nombre),
                   'PRODUCTO' 	   = pd_descripcion,
                   'CUENTA' 	   = rle_cuenta,
                   'LISTA NEGRA'   = rle_lista_negra,
                   'LISTA PEP' 	   = rle_lista_pep,
                   'LISTA PR' 	   = rle_lista_pr,
                   'COD PRODUCTO'  = rle_producto,
                   'NUM PROCESO'   = rle_proceso,
                   'ID ROL' 	   = rle_rol,
                   'USUARIO' 	   = rle_usuario,
                   'ACCIONES' 	   = rle_acciones,
                   'OBSERVACIONES' = rle_observaciones
             from  cobis..cl_validacion_listas_externas vle,
                   cobis..cl_ente,
                   cobis..cl_producto
             where rle_ente                           = en_ente
               and rle_producto                       = pd_producto
               and cast(rle_fecha_validacion as date) between CAST(@i_fecha_desde as date) and CAST(@i_fecha_hasta as date)
               and rle_producto                       = isnull(@i_producto,rle_producto)
               and rle_cuenta                         = isnull(@i_cuenta,rle_cuenta)
               and rle_ente                           = isnull(@i_ente,rle_ente)
               and (rle_lista_negra                   is not null
                or  rle_lista_pep                     is not null
                or  rle_lista_pr                      is not null)
               and rle_observaciones                  is not null
          order by rle_ente asc
            if (@@rowcount = 0)
              begin
                --NO EXISTEN REGISTROS
                exec sp_cerror
                     @t_debug      = @t_debug,
                     @t_file       = @t_file,
                     @t_from       = @w_sp_name,
                     @i_num        = 1720081
                return 1720081
              end

            return 0
          end

        if (@i_tiene_observacion = 'N')
          begin
            select 'FECHA' 		   = rle_fecha_validacion,
                   'CLIENTE' 	   = rle_ente,
                   'NOMBRE' 	   = isnull(en_nomlar,en_nombre),
                   'PRODUCTO' 	   = pd_descripcion,
                   'CUENTA' 	   = rle_cuenta,
                   'LISTA NEGRA'   = rle_lista_negra,
                   'LISTA PEP' 	   = rle_lista_pep,
                   'LISTA PR' 	   = rle_lista_pr,
                   'COD PRODUCTO'  = rle_producto,
                   'NUM PROCESO'   = rle_proceso,
                   'ID ROL' 	   = rle_rol,
                   'USUARIO' 	   = rle_usuario,
                   'ACCIONES' 	   = rle_acciones,
                   'OBSERVACIONES' = rle_observaciones
             from  cobis..cl_validacion_listas_externas vle,
                   cobis..cl_ente,
                   cobis..cl_producto
             where rle_ente                           = en_ente
               and rle_producto                       = pd_producto
               and cast(rle_fecha_validacion as date) between CAST(@i_fecha_desde as date) and CAST(@i_fecha_hasta as date)
               and rle_producto                       = isnull(@i_producto,rle_producto)
               and rle_cuenta                         = isnull(@i_cuenta,rle_cuenta)
               and rle_ente                           = isnull(@i_ente,rle_ente)
               and (rle_lista_negra                   is not null
                or  rle_lista_pep                     is not null
                or  rle_lista_pr                      is not null)
               and rle_observaciones                  is null
          order by rle_ente asc
            if (@@rowcount = 0)
              begin
                --NO EXISTEN REGISTROS
                exec sp_cerror
                     @t_debug      = @t_debug,
                     @t_file       = @t_file,
                     @t_from       = @w_sp_name,
                     @i_num        = 1720081
                return 1720081
              end

            return 0
          end
      end

    if (@i_fecha_desde is  null or @i_fecha_hasta is  null or @i_tiene_observacion is null)
      begin
        --NO DEBEN IR NULOS LOS CAMPOS
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720185
        return 1720185
      end
  end

if (@i_operacion = 'D')
  begin
    delete cobis..cl_validacion_listas_externas
     where rle_producto = @i_producto
       and rle_cuenta   = @i_cuenta
       and rle_proceso  = @i_proceso
  end
 
if (@i_operacion = 'T' or @i_param2 = 'T')
begin 
   if @i_param2 = 'T' 
      select @i_fecha = @i_param1
		
   create table #tmp (
      en_id        int   identity,
      en_subtipo   char(1),
      en_nombre    varchar(160),
      p_p_apellido varchar(16),
      p_s_apellido varchar(16),
      en_ced_ruc   varchar(30),
      p_fecha_nac  datetime,
      rle_ente	 int,
      rle_rol		 varchar(10)
      )
      
   insert into #tmp 
   (en_subtipo, en_nombre, p_p_apellido, p_s_apellido, en_ced_ruc, p_fecha_nac, rle_ente, rle_rol)
      select 
      en_subtipo,
      (cobis.dbo.fn_filtra_acentos(upper(rtrim(ltrim( isnull(en_nombre,'')))))),
      (cobis.dbo.fn_filtra_acentos(upper(rtrim(ltrim( isnull(p_p_apellido,'') ))))),
      (cobis.dbo.fn_filtra_acentos(upper(rtrim(ltrim( isnull(p_s_apellido,'') ))))),
      UPPER(en_ced_ruc),
      p_fecha_nac,
      rle_ente,
      rle_rol
      from cobis..cl_validacion_listas_externas vle
      left outer join cobis..cl_ente cli on vle.rle_ente = cli.en_ente
      left outer join cobis..cl_producto pro on vle.rle_producto = pro.pd_producto
      where vle.rle_producto = isnull(@i_producto, vle.rle_producto)
      and vle.rle_cuenta = isnull(@i_cuenta, vle.rle_cuenta)
      and cast(vle.rle_fecha_validacion as date) = @i_fecha
      and vle.rle_proceso = isnull(@i_proceso, vle.rle_proceso)

   select @w_registros_totales = count(*) from #tmp
   select @w_registros_procesados = 1

   if @w_registros_totales > 0 
   begin 
      while @w_registros_procesados <= @w_registros_totales
      begin 
         SELECT @w_subtipo = 'P'
         SELECT @w_nombre = en_nombre, @w_p_apellido = p_p_apellido, @w_s_apellido = p_s_apellido,
                @w_ced_ruc = en_ced_ruc, @w_fecha_nac = p_fecha_nac, @w_ente = rle_ente, @w_rol = rle_rol FROM #tmp
                WHERE en_id = @w_registros_procesados

    
         /*Listas Negras*/
         select @w_negras = case when count(*) > 0 then 1 else 0 end
         from cobis..cl_listas_negras
         where px_excluidos_id    = 2  -- ListasNegras
         and ((upper(pe_nombre)   = @w_nombre
         and   upper(pe_paterno)  = @w_p_apellido
         and   upper(pe_materno)  = @w_s_apellido
         and   upper(pe_curp)     = @w_ced_ruc)
         or   (upper(pe_razonsoc) = @w_nombre
         and   upper(pe_rfc)      = @w_ced_ruc))

         /* Personas Expuestas Politicamente */
         select @w_pep = case when count(*) > 0 then 1 else 0 end
         from cobis..cl_listas_negras
         where px_excluidos_id      = 3  -- PEP
         and ((upper(pe_nombre)   = @w_nombre
         and   upper(pe_paterno)  = @w_p_apellido
         and   upper(pe_materno)  = @w_s_apellido
         and   upper(pe_curp)     = @w_ced_ruc)
         or   (upper(pe_razonsoc) = @w_nombre
         and   upper(pe_rfc)      = @w_ced_ruc))

         print @w_pep

         /* Personas Relacionadas */
         select @w_relacionadas = case when count(*) > 0 then 1 else 0 end
         from cobis..cl_listas_negras
         where px_excluidos_id      = 1  -- pr
         and ((upper(pe_nombre)   = @w_nombre
         and   upper(pe_paterno)  = @w_p_apellido
         and   upper(pe_materno)  = @w_s_apellido
         and   upper(pe_curp)     = @w_ced_ruc)
         or   (upper(pe_razonsoc) = @w_nombre
         and   upper(pe_rfc)      = @w_ced_ruc))


         /* Posterior a la definicion del cliente, se procede a actualizar la base de datos */
         update cobis..cl_validacion_listas_externas
         set rle_lista_negra = case when @w_negras > 0 
                        then 'S' 
                        else 'N' 
                     end,
         rle_lista_pep   = case when @w_pep > 0 
                        then 'S' 
                        else 'N' 
                     end,
         rle_lista_pr    = case when @w_relacionadas > 0 
                        then 'S' 
                        else 'N' 
                     end              
         where rle_ente        = @w_ente
         and rle_rol         = @w_rol
  
         /*Actualizamos el numero del contador para avanzar con el siguiente registro*/
         select @w_registros_procesados = @w_registros_procesados + 1
         
      end 
   end 
end

if (@i_operacion = 'Q')
  begin
    if (@i_ente is not null and @i_producto is not null and @i_cuenta is not null and @i_fecha is not null)
      begin
        select 'FECHA' 		   = rle_fecha_validacion,
               'CLIENTE' 	   = rle_ente,
               'ROL' 		   = rle_rol,
               'PROCESO' 	   = rle_proceso,
               'PRODUCTO' 	   = pd_descripcion,
               'CUENTA' 	   = rle_cuenta,
               'LISTA NEGRA'   = rle_lista_negra,
               'LISTA PEP' 	   = rle_lista_pep,
               'LISTA PR' 	   = rle_lista_pr,
               'USUARIO' 	   = rle_usuario,
               'OBSERVACIONES' = rle_observaciones,
               'ACCIONES' 	   = rle_acciones
          from cobis..cl_validacion_listas_externas vle,
               cobis..cl_ente,
               cobis..cl_producto
         where rle_ente = en_ente
           and rle_producto = pd_producto
           and cast(rle_fecha_validacion as date) =  @i_fecha
           and rle_ente                           = isnull(@i_ente,rle_ente)
           and rle_producto                       = isnull(@i_producto,rle_producto)
           and rle_cuenta                         = isnull(@i_cuenta,rle_cuenta)
        if (@@rowcount = 0)
          begin
            --NO EXISTEN REGISTROS
            exec sp_cerror
                 @t_debug      = @t_debug,
                 @t_file       = @t_file,
                 @t_from       = @w_sp_name,
                 @i_num        = 1720187
            return 1
          end

        return 0
      end

    if (@i_ente is null or @i_producto is null or @i_cuenta is null or @i_fecha is null)
      begin
        --NO EXISTEN REGISTROS
        exec sp_cerror
             @t_debug      = @t_debug,
             @t_file       = @t_file,
             @t_from       = @w_sp_name,
             @i_num        = 1720188
        return 0
      end

  end

go


/*Fragmento de codigo retirado*/
/*
if (@i_operacion = 'T')
  begin 
    declare cursor_clientes cursor for
    select en_subtipo,
           upper(en_nombre),
           upper(p_p_apellido),
           upper(p_s_apellido),
           en_ced_ruc,
           p_fecha_nac,
           rle_ente,
           rle_rol
      from cobis..cl_validacion_listas_externas vle, cobis..cl_ente, cobis..cl_producto
     where rle_ente           = en_ente
       and rle_producto       = pd_producto
       and rle_producto       = isnull(@i_producto,rle_producto)
       and rle_cuenta       = isnull(@i_cuenta,rle_cuenta)
       and cast(rle_fecha_validacion as date) = @i_fecha
       and rle_proceso         = isnull(@i_proceso,rle_proceso)

     open cursor_clientes
    fetch next from cursor_clientes 
     into @w_subtipo,
          @w_nombre,
          @w_p_apellido,
          @w_s_apellido,
          @w_ced_ruc,
          @w_fecha_nac,
          @w_ente,
          @w_rol

    while @@fetch_status <> -1
      begin
        print '----EN_ENTE----'
        print @w_ente

         LISTAS NEGRAS 
        select @w_negras          = case when count(*) > 0 
                                      then 1 
                                      else 0
                                    end
          from cobis..cl_listas_negras
         where px_excluidos_id      = 2  -- LN
           and ((upper(pe_nombre)   = @w_nombre
           and   upper(pe_paterno)  = @w_p_apellido
           and   upper(pe_materno)  = @w_s_apellido
           and   upper(pe_curp)     = @w_ced_ruc
           and   @w_subtipo         = 'p')
            or  (upper(pe_razonsoc) = @w_nombre
           and   upper(pe_rfc)      = @w_ced_ruc))
                  
        print @w_negras
        
         LISTAS PEP 
        select @w_pep               = case when count(*) > 0 
                                         then 1 
                                         else 0
                                       end
          from cobis..cl_listas_negras
         where px_excluidos_id      = 3  -- PEP
           and ((upper(pe_nombre)   = @w_nombre
           and   upper(pe_paterno)  = @w_p_apellido
           and   upper(pe_materno)  = @w_s_apellido
           and   upper(pe_curp)     = @w_ced_ruc
           and   @w_subtipo         = 'P')
            or  (upper(pe_razonsoc) = @w_nombre
           and   upper(pe_rfc)      = @w_ced_ruc))
        
        print @w_pep
        
        PERSONAS RELACIONADAS 
        select @w_relacionadas      = case when count(*) > 0 
                                         then 1 
                                         else 0
                                       end
          from cobis..cl_listas_negras
         where px_excluidos_id      = 1  -- pr
           and ((upper(pe_nombre)   = @w_nombre
           and   upper(pe_paterno)  = @w_p_apellido
           and   upper(pe_materno)  = @w_s_apellido
           and   upper(pe_curp)     = @w_ced_ruc
           and   @w_subtipo         = 'P')
            or  (upper(pe_razonsoc) = @w_nombre
           and   upper(pe_rfc)      = @w_ced_ruc))

        print  @w_relacionadas
        
        if (@@fetch_status = -2)
          begin
            close cursor_clientes
            deallocate cursor_clientes
            
             Error en recuperacion de datos del cursor 
            exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 1720186
            return 1
          end
        
        LISTAS NEGRAS
        update cobis..cl_validacion_listas_externas
           set rle_lista_negra = case when @w_negras > 0 
                                      then 'S' 
                                      else 'N' 
                                 end,
               rle_lista_pep   = case when @w_pep > 0 
                                      then 'S' 
                                      else 'N' 
                                 end,
               rle_lista_pr    = case when @w_relacionadas > 0 
                                      then 'S' 
                                      else 'N' 
                                 end              
         where rle_ente        = @w_ente
           and rle_rol         = @w_rol
           and rle_producto    = @i_producto
           and rle_cuenta      = @i_cuenta
           and rle_proceso     = @i_proceso

        --FETCH NEXT FROM cursor_clientes
        fetch next from cursor_clientes 
         into @w_subtipo,
              @w_nombre,
              @w_p_apellido,
              @w_s_apellido,
              @w_ced_ruc,
              @w_fecha_nac,
              @w_ente,
              @w_rol
      end
    close cursor_clientes
    deallocate cursor_clientes  
  end
*/