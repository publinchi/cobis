use cob_interface
go

/************************************************************/
/*   ARCHIVO:         sp_cliente_garantia_bsn_int.sp        */
/*   NOMBRE LOGICO:   sp_cliente_garantia_bsn_int           */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de COBIS CORP                                */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de COBIS CORP.                             */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a COBIS CORP para obtener ordenes  de secuestro*/
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*Interfaz que asocia cliente con la solicitud de una       */
/*garantia                                                  */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 22/MAR/2022     pmoreno             Emision Inicial      */
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_cliente_garantia_bsn_int')
   drop proc sp_cliente_garantia_bsn_int
go

create proc sp_cliente_garantia_bsn_int (
        @s_ssn                int             = null,
        @s_date               datetime        = null,
        @s_user               login           = null,
        @s_term               descripcion     = null,
        @s_ofi                smallint        = null,
        @s_srv                varchar(30)     = null,
        @s_rol                smallint        = null,
        @s_lsrv               varchar(30)     = null,
        @s_sesn               int             = null,
        @s_org                char(1)         = null,
        @s_culture            varchar(10)     = null,
        @t_trn                smallint        = null,
        @t_debug              char(1)         = 'N',
        @t_file               varchar(14)     = null,
        @t_from               varchar(30)     = null,
        @t_show_version       bit             = 0,
        @i_operacion          char(1)         = null,
        @i_modo               smallint        = null,
        @i_filial             tinyint         = null,
        @i_sucursal           smallint        = null,
        @i_custodia           int             = null,
        @i_tipo_cust          descripcion     = null,
        @i_ente               int             = null,
        @i_principal          char(1)         = null,
        @i_cliente            int             = null,
        @i_oficial            int             = null,
        @i_nombre             descripcioncryp = null, --RZ
        @i_ssn                int             = null,
        @i_codigo_externo     varchar(64)     = null    --AGU
)
as
declare @w_today              datetime,       -- fecha del dfa
        @w_sp_name            varchar(32),    -- nombre stored proc
        @w_existe             tinyint,        -- existe el registro
        @w_filial             tinyint,
        @w_sucursal           smallint,
        @w_custodia           int,
        @w_tipo_cust          descripcion,
        @w_ente               int,
        @w_grupo              int,            --Vivi
        @w_error              int,
        @w_codigo_externo     varchar(64),
        @w_oficial            smallint,
        @w_nombre             descripcioncryp,--RZ
        @w_seccliente         int,
        @w_tipo               catalogo,                      
        @w_tramite            int ,          
        @w_tmitigador         catalogo,      
        @w_secuencial        int,      
        @w_return             int,
        @w_fetch_status       int
      
select @w_today   = convert(varchar(10),getdate(),101),
       @w_sp_name = 'sp_cliente_garantia_bsn_int'

--Verifica version de programa
if @t_show_version = 1
begin
   print 'Stored Procedure, Version 4.0.0.0 ' + @w_sp_name
   return 0
end

if @i_codigo_externo is not null
begin

      exec @w_error     = cob_custodia..sp_compuesto
           @t_trn       = 19245,
           @i_operacion = 'Q',
           @i_compuesto = @i_codigo_externo,
           @o_filial    = @i_filial     out,
           @o_sucursal  = @i_sucursal   out,
           @o_tipo      = @i_tipo_cust  OUT,
           @o_custodia  = @i_custodia   OUT,
           @o_secuencia = @w_secuencial out
      if @w_error != 0
     begin
       goto error
     end
end

--**********************************************
-- Codigos de Transacciones
                        
if (@t_trn <> 21843 and @i_operacion = 'I') or 
   (@t_trn <> 21844 and @i_operacion = 'D') 
begin
   --tipo de transacci=n no corresponde
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901006
   return 1 
end
--Chequeo de Existencias
--*************************
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
   select @w_filial         = cg_filial,
          @w_sucursal       = cg_sucursal,
          @w_custodia       = cg_custodia,
          @w_tipo_cust      = cg_tipo_cust,
          @w_ente           = cg_ente,
          @w_codigo_externo = cg_codigo_externo,
          @w_oficial        = cg_oficial,
          @w_nombre         = substring(cg_nombre,1,datalength(cg_nombre)),
          @w_codigo_externo = cg_codigo_externo
   from cob_custodia..cu_cliente_garantia
   where cg_filial    = @i_filial 
     and cg_sucursal  = @i_sucursal 
     and cg_tipo_cust = @i_tipo_cust 
     and cg_custodia  = @i_custodia 
     and cg_ente      = @i_ente           
            
   if @@rowcount > 0
    select @w_existe = 1
   else
      select @w_existe = 0
end
--VALIDACION DE CAMPOS NULOS
--******************************
if @i_operacion = 'I' or @i_operacion = 'U'
begin
   if @i_filial    = null or 
      @i_sucursal  = null or 
      @i_custodia  = null or 
      @i_tipo_cust = null or 
      @i_ente      = null 
   begin
      --Campos NOT NULL con valores nulos
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901001
      return 1 
   end
end
--RZ para el manejo del nombre del cliente o ente encriptado
if @i_operacion = 'I' or @i_operacion = 'U' or @i_operacion = 'T'
begin
   select @i_nombre = substring(en_nomlar,1,datalength(en_nomlar))   
   from cobis..cl_ente
   where en_ente  = @i_ente
end

-- Insercion del registro
--***********************
if @i_operacion = 'T' 
begin
   begin tran
      if @i_ssn = 0 -- null
      begin
         select @i_ssn = @s_ssn
      end
      insert into cob_custodia..cu_cliente_garantia_tmp(
             cg_ssn,
             cg_filial,
             cg_sucursal,
             cg_custodia,
             cg_tipo_cust,
             cg_ente,
             cg_principal,
             cg_oficial,
             cg_nombre)
      values (
             @i_ssn,
             @i_filial,
             @i_sucursal,
             @i_custodia,
             @i_tipo_cust,
             @i_ente,
             @i_principal,
             @i_oficial,
             @i_nombre)
           
      if @@error <> 0 
      begin
         --Error en inserci=n de registro
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1903001
         return 1 
      end
     
      select @w_seccliente = @i_ssn
      select @w_seccliente
   commit tran 
   return 0
end
--**********************
         
if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      --Registro ya existe
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901002
      return 1 
   end
   
   

   --*******************************   
   --*** BES - 20092017 
   --*** Garantias   
   --*******************************
   IF @i_custodia IS NULL
   BEGIN
      select @w_secuencial = se_actual
      from cob_custodia..cu_seqnos
      where --PQU integracion se_codigo   = @i_tipo_cust
      se_tipo_cust   = @i_tipo_cust
      --and se_filial   = @i_filial   
   
      if @w_secuencial = 9999999
           print 'Secuencial llego al limite'
   END
   ELSE
       SELECT @w_secuencial = @i_custodia
       
   set @w_custodia = @w_secuencial
   
   /*PQU integracion
   select @w_tmitigador=substring(ta_tipo_mitigador, 1, 3)
     from cob_custodia..cu_tipo_custodia_adi
   where ta_tipo=@i_tipo_cust
   */
   
   select @w_tmitigador = ISNULL(@w_tmitigador, '')
      
   -- CODIGO EXTERNO
   exec @w_return = cob_custodia..sp_externo
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @w_custodia,                             
        @o_compuesto = @w_codigo_externo OUT
        
   --*******************************   
   --*** FIN   
   --*******************************     
      insert into cob_custodia..cu_cliente_garantia(
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
      begin
         --Error en inserci=n de registro
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1903001
         return 1 
      end
   
      --Transaccion de Servicio
      --***********************
      insert into cob_custodia..ts_cliente_garantia
             values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
             @i_filial,
             @i_sucursal,
             @i_tipo_cust,
             @i_custodia,
             @i_ente,
             @i_principal,
             @i_codigo_externo)
      if @@error <> 0 
      begin
         --Error en inserci=n de transaccion de servicio
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1903003
         return 1 
      end
     PRINT 'fin'
     return 0
end

--Eliminacion de registros
--************************
if @i_operacion = 'D'
begin
   if @w_existe = 0
   begin
      --Registro a eliminar no existe
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1907002
      return 1 
   end
   
--***** Integridad Referencial ****
--*****                        ****
   begin tran
      delete cob_custodia..cu_cliente_garantia
      where cg_filial    = @i_filial 
        and cg_sucursal  = @i_sucursal 
        and cg_tipo_cust = @i_tipo_cust 
        and cg_custodia  = @i_custodia 
        and cg_ente      = @i_ente
                     
      if @@error <> 0
      begin
         --Error en eliminaci=n de registro
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
         update cob_custodia..cu_cliente_garantia
         set cg_principal = 'S'   -- (S)i
         where cg_filial    = @i_filial 
           and cg_sucursal  = @i_sucursal 
           and cg_tipo_cust = @i_tipo_cust
           and cg_custodia  = @i_custodia 
         
         set rowcount 0
         
         if @@error <> 0
         begin
            --Error en eliminaci=n de registro
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905001
            return 1 
         end
      end
     
      -- Transaccion de Servicio 
      --**************************
      insert into cob_custodia..ts_cliente_garantia
             values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_cliente_garantia',
             @w_filial,
             @w_sucursal,
             @w_tipo_cust,
             @w_custodia,
             @w_ente,
             NULL,
             @i_codigo_externo)
           
      if @@error <> 0 
      begin
         --Error en inserci=n de transacci=n de servicio
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

--Consulta opcion QUERY
--**********************
if @i_operacion = 'Q'
begin
   if @w_existe = 1
      select @w_filial,
             @w_sucursal,
             @w_custodia,
             @w_tipo_cust,
             @w_ente,
             @w_oficial,
             @w_nombre
   else
   begin
      --Registro no existe
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
      select  "17410" =  en_ente,
              "17411" =  substring(cg_nombre,1,datalength(cg_nombre)),  --RZ
              "17412" =  substring(en_ced_ruc,1,20),
              "17413" =  en_oficial,
              "17414" =  cg_principal
      from cob_custodia..cu_cliente_garantia,cobis..cl_ente 
      where cg_filial    = @i_filial 
        and cg_sucursal  = @i_sucursal 
        and cg_tipo_cust = @i_tipo_cust
        and cg_custodia  = @i_custodia 
        and cg_ente      = en_ente 
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
      select "17410" =  en_ente,
             "17411" =  substring(cg_nombre,1,datalength(cg_nombre)),   --RZ
             "17415" =  en_ced_ruc, 
             "17413" =  en_oficial  
      from cob_custodia..cu_cliente_garantia ,cobis..cl_ente 
      where cg_ente > @i_ente 
        and cg_filial    = @i_filial 
        and cg_sucursal  = @i_sucursal 
        and cg_tipo_cust = @i_tipo_cust 
        and cg_custodia  = @i_custodia 
        and cg_ente      = en_ente 
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
   if @i_cliente is null
      select @i_cliente = cg_ente 
      from cob_custodia..cu_cliente_garantia 
      where cg_codigo_externo = @i_codigo_externo
   
   if @i_codigo_externo is null
      select @i_codigo_externo = (select cu_codigo_externo from cob_custodia..cu_custodia 
                                                   
                                                           where cu_custodia = @i_custodia
                                                           and cu_tipo       = @i_tipo_cust)

   set rowcount 20
   create table #cliente (ente int, nombre descripcion, cedula varchar (24) null, oficial int null )
   
   -- VERIFICA QUE EXISTA LA GARANTIA
   if exists (select 1 from cob_credito..cr_gar_propuesta
               where gp_garantia = @i_codigo_externo)
   begin
      -- OBTIENE OBLIGACIONES DE ESA GARANTIA
      declare cursor_consulta cursor for
      select distinct tr_tramite, tr_tipo
      from cob_credito..cr_gar_propuesta,
           cob_credito..cr_tramite
      where gp_garantia  = @i_codigo_externo
        and gp_tramite   = tr_tramite
        and tr_tipo  in ('L', 'O', 'R', 'F', 'E')
      order by tr_tramite
      
      open cursor_consulta
      fetch cursor_consulta into @w_tramite, @w_tipo
     select @w_fetch_status = @@fetch_status  
                                    

      if @w_fetch_status = -1
      begin
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1909001 
         return 1 
      end
      if @w_fetch_status = -2
      begin
         close cursor_consulta
         return 0
      end

       while @w_fetch_status = 0
      begin
         --LINEA DE CREDITO
         if @w_tipo = 'L'
         begin
            select @w_ente  = li_cliente,
                   @w_grupo = li_grupo
            from cob_credito..cr_linea
            where li_tramite = @w_tramite

            if @w_ente is null
               insert into #cliente
               select gr_grupo, substring(gr_nombre,1, datalength(gr_nombre)), isnull( gr_ruc  , ''), null
               from cobis..cl_grupo 
               where gr_grupo = @w_grupo
               and gr_grupo > isnull( @i_cliente, 0)
            else
               insert into #cliente
               select en_ente, substring(en_nomlar,1,datalength(en_nomlar)), en_ced_ruc, en_oficial
               from cobis..cl_ente  
               where en_ente = @w_ente
               and en_ente > isnull( @i_cliente, 0)
         end
         else  
            insert into #cliente
            select de_cliente, substring(en_nomlar,1,datalength(en_nomlar)), en_ced_ruc, en_oficial
            from cob_credito..cr_deudores, cobis..cl_ente
            where de_tramite = @w_tramite
            and en_ente    = de_cliente
            and de_cliente > isnull( @i_cliente, 0)
         
         fetch cursor_consulta into @w_tramite, @w_tipo
      end -- While
     
      --PQU integracion close cursor_consulta
      --PQU integracion deallocate cursor cursor_consulta
   end
   
   set rowcount 20
   select distinct "17240" =  ente,
                   "17241" =   nombre,
                   "17417" =  cedula,
                   "17413" =  fu_nombre
              
   from #cliente,cobis..cl_funcionario, cobis..cc_oficial
                    
   where ente           > isnull( @i_cliente, 0)
     and oficial        = oc_oficial
     and oc_funcionario = fu_funcionario
   order by ente

   return 0 
end

if @i_operacion = 'V'
begin
   if exists (select * from cob_custodia..cu_cliente_garantia,cobis..cl_ente
              where cg_filial     = @i_filial
                and cg_sucursal   = @i_sucursal 
                and(cg_tipo_cust  = @i_tipo_cust or @i_tipo_cust is null)
                and(cg_custodia   = @i_custodia  or @i_custodia  is null)
                and cg_ente       = @i_cliente
                and cg_ente       = en_ente
                and en_ente       = @i_cliente)
   begin
      return 0
   end
   else
   begin
      return 1 
   end
end       
--Actualizacion del registro
--**************************
if @i_operacion = 'U'
begin
   if not exists (select * from cob_custodia..cu_cliente_garantia
                   where cg_filial    = @i_filial     
                     and cg_sucursal  = @i_sucursal  
                     and cg_tipo_cust = @i_tipo_cust  
                     and cg_custodia  = @i_custodia)  
   begin
      --Registro a actualizar no existe
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1905002
      return 1 
   end
   
   begin tran
      update cob_custodia..cu_cliente_garantia
         set cg_ente      = @i_ente,
             cg_nombre    = @i_nombre
       where cg_filial    = @i_filial 
         and cg_sucursal  = @i_sucursal
         and cg_tipo_cust = @i_tipo_cust
         and cg_custodia  = @i_custodia  
       
      if @@error <> 0 
      begin
         --Error en actualizaci=n de registro
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1905001
         return 1 
      end
     
      --Transaccion de Servicio
      --***********************
      insert into cob_custodia..ts_cliente_garantia
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
         --Error en inserci=n de transaccion de servicio
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = 1903003
         return 1 
      end
     
      --Transaccion de Servicio
      insert into cob_custodia..ts_cliente_garantia
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
         --Error en inserci=n de transacci=n de servicio
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

return 0

error:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = @w_error
return 1
GO