/*************************************************************************/
/*   Archivo:              cliente_garantia.sp                           */
/*   Stored procedure:     sp_cliente_garantia                           */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*   lectual. Su uso no  autorizado dara  derecho aÂ  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion                    */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_cliente_garantia') IS NOT NULL
   drop  PROC dbo.sp_cliente_garantia
go

create proc dbo.sp_cliente_garantia
 (
   @s_ssn                int         = null,
   @s_date               datetime    = null,
   @s_user               login       = null,
   @s_term               descripcion = null,
   @s_corr               char(1)     = null,
   @s_ssn_corr           int         = null,
   @s_ofi                smallint    = null,
   @t_rty                char(1)     = null,
   @t_trn                smallint    = null,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_custodia           int         = null,
   @i_tipo_cust          descripcion = null,
   @i_ente               int         = null,
   @i_principal          char(1)     = null,
   @i_cliente            int         = null,
   @i_oficial            smallint    = null,
   @i_nombre             descripcion = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_custodia           int,
   @w_tipo_cust          descripcion,
   @w_ente               int,
   @w_principal          char(1),
   @w_error              int,
   @w_codigo_externo     varchar(64),
   @w_oficial            int,
   @w_nombre             descripcion


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_cliente_garantia'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19040 and @i_operacion = 'I') or
   (@t_trn <> 19041 and @i_operacion = 'U') or
   (@t_trn <> 19042 and @i_operacion = 'D') or
   (@t_trn <> 19043 and @i_operacion = 'V') or
   (@t_trn <> 19044 and @i_operacion = 'S') or
   (@t_trn <> 19045 and @i_operacion = 'Q') or
   (@t_trn <> 19046 and @i_operacion = 'A') or
   (@t_trn <> 19047 and @i_operacion = 'C') or
   (@t_trn <> 19048 and @i_operacion = 'Z')
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
         @w_filial = cg_filial,
         @w_sucursal = cg_sucursal,
         @w_custodia = cg_custodia,
         @w_tipo_cust = cg_tipo_cust,
         @w_ente = cg_ente,
         @w_codigo_externo = cg_codigo_externo,
         @w_oficial        = cg_oficial,
         @w_nombre         = cg_nombre
    from cob_custodia..cu_cliente_garantia
    where 
         cg_filial    = @i_filial and
         cg_sucursal  = @i_sucursal and
         cg_tipo_cust = @i_tipo_cust and
         cg_custodia  = @i_custodia and
         cg_ente      = @i_ente           

    if @@rowcount > 0
            select @w_existe = 1
    else

            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         @i_filial = NULL or 
         @i_sucursal = NULL or 
         @i_custodia = NULL or 
         @i_tipo_cust = NULL or 
         @i_ente = NULL 
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

    begin tran
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         insert into cu_cliente_garantia(
              cg_filial,
              cg_sucursal,
              cg_custodia,
              cg_tipo_cust,
              cg_ente,
              cg_principal,
              cg_codigo_externo,
              cg_oficial,
              cg_nombre)
         values (
              @i_filial,
              @i_sucursal,
              @i_custodia,
              @i_tipo_cust,
              @i_ente,
              @i_principal,
              @w_codigo_externo,
              @i_oficial,
              @i_nombre)

         if @@error <> 0 
         /*begin*/
         /* Error en insercion de registro */
             /*exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end*/

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_cliente_garantia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_ente,
         @i_principal,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
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
         delete cob_custodia..cu_cliente_garantia
    where 
         cg_filial = @i_filial and
         cg_sucursal = @i_sucursal and
         cg_tipo_cust = @i_tipo_cust and
         cg_custodia = @i_custodia and
         cg_ente = @i_ente

                          
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

         if @i_principal = 'S'  -- SE TRATA DEL PRINCIPAL
         begin 
            set rowcount 1
            update cu_cliente_garantia
            set cg_principal    = 'S'  -- (S)i
            where cg_filial     = @i_filial 
              and cg_sucursal   = @i_sucursal
              and cg_tipo_cust  = @i_tipo_cust
              and cg_custodia   = @i_custodia 
            set rowcount 0

            if @@error <> 0
            begin
            /*Error en eliminacion de registro */
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1905001
              return 1 
            end
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_cliente_garantia
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_ente,
         NULL,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
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
              @w_custodia,
              @w_tipo_cust,
              @w_ente,
              @w_oficial,
              @w_nombre
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

if @i_operacion = 'S'
begin
      set rowcount 20
      if @i_modo = 0 
      begin
         select "ENTE" = en_ente,
                "NOMBRE" = cg_nombre,
                "CEDULA-RUC" = substring(en_ced_ruc,1,20),
                "OFICIAL" = en_oficial,
                "PRINCIPAL" = cg_principal
         from cu_cliente_garantia,cobis..cl_ente 
         where cg_filial = @i_filial and
               cg_sucursal = @i_sucursal and
               cg_tipo_cust = @i_tipo_cust and
               cg_custodia = @i_custodia and
               cg_ente = en_ente 
         order by cg_ente 
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end
      end
      else 
      begin
         select "ENTE" = en_ente,
                "NOMBRE" = cg_nombre,
                "CEDULA" = en_ced_ruc, 
                "OFICIAL" = en_oficial  
         from cu_cliente_garantia ,cobis..cl_ente 
         where cg_ente > @i_ente and
               cg_filial = @i_filial and
               cg_sucursal = @i_sucursal and
               cg_tipo_cust = @i_tipo_cust and
               cg_custodia = @i_custodia and
               cg_ente = en_ente 
         order by cg_ente 
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'C'
begin
    set rowcount 20
    select 
           'CLIENTE'  = cg_ente,
           ' ' = cg_nombre,
           'PRINCIPAL' = cg_principal,
           'CI o RUC'     = en_ced_ruc,
           'OFICIAL'    = en_oficial,
           'GRUPO ECONOMICO'    = en_grupo,
           'CALIFICACION'  = en_calificacion
      from cu_cliente_garantia,cu_custodia,cobis..cl_ente
     where cg_filial         = @i_filial
       and cg_sucursal       = @i_sucursal
       and cg_tipo_cust      = @i_tipo_cust 
       and cg_custodia       = @i_custodia 
       and cg_codigo_externo = cu_codigo_externo
       and cg_ente           = en_ente
       and (cg_ente > @i_cliente or @i_cliente is null) 
     order by cg_tipo_cust,cg_custodia,cg_ente
     if @@rowcount = 0
     begin
           /*exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003*/
           return 1 
     end
     return 0 
end

if @i_operacion = 'V'
begin
    if exists (select  * 
       from cu_cliente_garantia,cobis..cl_ente
      where cg_filial = @i_filial

        and cg_sucursal = @i_sucursal
        and (cg_tipo_cust = @i_tipo_cust or @i_tipo_cust is null)
        and (cg_custodia = @i_custodia  or @i_custodia is null)
        and cg_ente = @i_cliente
        and cg_ente = en_ente)
     begin
           return 0
     end
     else
     begin
           /*exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004*/
           return 1 
     end
end       

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if not exists (select * from cu_cliente_garantia
                    where cg_filial    =   @i_filial     
                      and cg_sucursal  =   @i_sucursal   
                      and cg_tipo_cust =   @i_tipo_cust  
                      and cg_custodia  =   @i_custodia)  
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

        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out

         update cob_custodia..cu_cliente_garantia
         set    cg_ente      = @i_ente,
                cg_nombre    = @i_nombre
         where  cg_filial    = @i_filial and
                cg_sucursal  = @i_sucursal and
                cg_tipo_cust = @i_tipo_cust and
                cg_custodia  = @i_custodia  

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

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_cliente_garantia
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
         @w_filial,
         @w_sucursal,
         @w_tipo_cust,
         @w_custodia,
         @w_ente,
         NULL,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_cliente_garantia
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
         @i_filial,
         @i_sucursal,
         @i_tipo_cust,
         @i_custodia,
         @i_ente,
         NULL,
         @w_codigo_externo)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end


/* Declaracion de cursor */
/*if @i_operacion = 'Z'
begin
   
  create table cu_cliente_temporal (
          filial     tinyint,
          sucursal   smallint,
          tipo       varchar(64),
          custodia   int,
          cliente    int,
          nombre     varchar(64)
     )
   

    declare cliente_garantia cursor
    for
    select cu_tipo,cu_custodia
      from cu_custodia        
     where cu_filial    = @i_filial
       and cu_sucursal  = @i_sucursal
       --and (cu_tipo = @i_tipo_cust or @i_tipo_cust is null)
       --and (cg_custodia  = @i_custodia or @i_custodia is null)

    open cliente_garantia
    fetch cliente_garantia into @w_tipo_cust,
                                @w_custodia

    while @@sqlstatus != 2
       begin
           insert into cu_cliente_temporal
           select cg_filial,cg_sucursal,cg_tipo_cust,cg_custodia,cg_ente,
                --p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
                  cg_nombre
             from cu_cliente_garantia,cu_custodia --,cobis..cl_ente   
            where cg_filial            = @i_filial
              and cg_sucursal          = @i_sucursal
              and cg_tipo_cust         = @w_tipo_cust
              and cg_custodia          = @w_custodia
              and cg_codigo_externo    = cu_codigo_externo
              and (cg_ente <> @i_cliente) 
              --and cg_ente      = en_ente
        end
     fetch cliente_garantia into @w_tipo_cust,
                                 @w_custodia
     deallocate cursor cliente_garantia

        select "FILIAL" = cg_filial, "SUCURSAL" = cg_sucursal,
           "TIPO" = tipo,"GARANTIA" = custodia,"CLIENTE" = cliente,
           "" = nombre 
          from cu_cliente_temporal,cu_cliente_garantia 
    drop table cu_cliente_temporal
end */


return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
go