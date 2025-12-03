/************************************************************************/
/*   Archivo:             sp_fiadores_grp_batch.sp                      */
/*   Stored procedure:    sp_fiadores_grp_batch                         */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  27-Septiembre-2023                            */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se crea/asocia fiadores para grupos con mas de 15 miembros         */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 27-Septiembre-2023       BDU                Emision Inicial          */
/* 01-Diciembre-2023        BDU             R220601-Agregar garantias   */
/*                                          existentes                  */
/* 12-Diciembre-2023        BDU             R221319-Ajustar logica      */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'sp_fiadores_grp_batch')
begin
   drop proc sp_fiadores_grp_batch
end   
go

create procedure sp_fiadores_grp_batch(
 @s_ssn        int         = 1,
 @s_user       login       = 'operador',
 @s_sesn       int         = 1,
 @s_term       varchar(30) = 'CONSOLA',
 @s_date       datetime    = null,
 @s_srv        varchar(30) = 'HOST',
 @s_lsrv       varchar(30) = 'HOST',
 @s_ofi        smallint    = 1,
 @s_rol        smallint    = null
)
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_id                       int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_return                   int, 
        @w_tramite                  int,
        @w_tramite_aux              int,
        @w_tramite_aux_2            int,
        @w_filial                   int,
        @w_oficina                  int,
        @w_tipo_personal            varchar(10),
        @w_ente                     int,
        @w_garante                  int,
        @w_codigo_externo           varchar(64),
        @w_banco_padre              varchar(24),
        @w_min_cli                  int,
        @w_max_cli                  int,
        @w_min_gar                  int,
        @w_max_gar                  int,
        @w_min_inst                 int,
        @w_max_inst                 int
        
-- Información proceso batch
PRINT 'INICIA ASIGNACION DE FIADORES'
select @w_termina = 0,
       @s_date = getdate()

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..sp_fiadores_grp_batch%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR_FIN
end

/*
select @w_sarta = 21000,
       @w_batch = 21017*/
--Parametro
select @w_tipo_personal = pa_char
  from cobis..cl_parametro
 where pa_producto = 'GAR'
   and pa_nemonico = 'GARGPE' 

--Tablas temporales
if (OBJECT_ID('tempdb.dbo.#tmp_clients','U')) is not null
begin
    drop table #tmp_clients
end    
create table #tmp_clients (
 tg_id       int  identity(1,1),
 tg_cliente  int  null,
 op_tramite  int  null,
 op_filial   int  null,
 op_oficina  int  null
)
      
create  nonclustered index tmp_clients_id
on #tmp_clients  (tg_id asc)

create  nonclustered index tmp_clients_cli
on #tmp_clients  (tg_cliente asc)

if (OBJECT_ID('tempdb.dbo.#tmp_gar','U')) is not null
begin  
    drop table #tmp_gar
end    
create table #tmp_gar (
 tg_cliente  int  null
)
create  nonclustered index tmp_gar_cli
on #tmp_gar  (tg_cliente asc)

 if (OBJECT_ID('tempdb.dbo.#tmp_gar_cod','U')) is not null
begin  
    drop table #tmp_gar_cod
end    
create table #tmp_gar_cod (
 gc_tramite  int  null,
 gc_cod_externo varchar(64) null
)
create  nonclustered index tmp_gar_cod
on #tmp_gar_cod  (gc_tramite asc)

 if (OBJECT_ID('tempdb.dbo.#tmp_inst_proc','U')) is not null
begin  
    drop table #tmp_inst_proc
end    
create table #tmp_inst_proc (
 ip_id         int  identity(1,1),
 ip_tramite    int  not null 
)
create  nonclustered index tmp_ip_id
on #tmp_inst_proc  (ip_id)

insert into #tmp_inst_proc
select distinct wip.io_campo_3
from cob_credito.dbo.cr_tramite_grupal cg with(nolock)
inner join cob_workflow.dbo.wf_inst_proceso wip with(nolock)  on cg.tg_tramite = wip.io_campo_3
where wip.io_campo_5 = 1

--SACAR MIN MAX DE LA TMP
select @w_min_inst = min(ip_id),
       @w_max_inst = max(ip_id)
from #tmp_inst_proc

--While de operaciones
while @w_min_inst <= @w_max_inst
begin      
    --Valor del tramite actual
    select @w_tramite = ip_tramite
    from #tmp_inst_proc
    where ip_id = @w_min_inst
    
    Print 'Procesando tramite ' + convert(varchar, @w_tramite) 
    insert into #tmp_clients
    select tg_cliente,
           op_tramite,
           of_filial,
           op_oficina
    from cob_credito..cr_tramite_grupal with(nolock)
    inner join cob_cartera..ca_operacion with(nolock) on tg_operacion = op_operacion
    inner join cobis..cl_oficina on of_oficina =  op_oficina
    where tg_tramite = @w_tramite 
    and tg_participa_ciclo = 'S'
    order by tg_cliente
    
    print 'insertado clientes'
    
    insert into #tmp_gar
    select tg_cliente
    from #tmp_clients 
    order by tg_cliente
   
        --Crear garantias
    select @w_min_cli = min(tg_id),
           @w_max_cli = max(tg_id)
    from #tmp_clients
    
    while @w_min_cli <= @w_max_cli
    begin 
        select  @w_ente = tg_cliente, 
                @w_tramite_aux = op_tramite, 
                @w_filial = op_filial, 
                @w_oficina = op_oficina
        from #tmp_clients
        where tg_id = @w_min_cli
        Print 'Garantias crear Id [' + CONVERT(VARCHAR, @w_min_cli) + ']  tramite ' + convert(varchar, @w_tramite_aux)  + '  cliente ' + convert(varchar, @w_ente)
        --Creo la garantia personal para cada uno
       if not exists (select 1 from cob_credito..cr_gar_propuesta with(nolock), cob_custodia..cu_custodia with(nolock) 
                             where gp_garantia = cu_codigo_externo
                               and gp_tramite  = @w_tramite_aux 
                               AND cu_garante  = @w_ente
                               and cu_descripcion = 'GARGPE')
       begin
           exec @w_return = cob_pac..sp_custodia_busin
                @s_srv                 = @s_srv,
                @s_user                = @s_user,
                @s_term                = @s_term,
                @s_ofi                 = @w_oficina,
                @s_rol                 = @s_rol,
                @s_ssn                 = @s_ssn,
                @s_lsrv                = @s_lsrv,
                @s_date                = @s_date,
                @s_sesn                = @s_sesn,
                @t_trn                 = 19090,
                @t_timeout             = 180,
                @i_operacion           = 'I',
                @i_filial              = @w_filial,
                @i_sucursal            = @w_oficina,
                @i_tipo                = @w_tipo_personal,
                @i_estado              = 'P',
                @i_garante             = @w_ente,
                @i_cliente             = @w_ente,
                @i_valor_inicial       = 0,
                @i_valor_actual        = 0,
                @i_valor_avaluo        = 0,
                @i_moneda              = 0,
                @i_descripcion         = 'GARGPE',
                @i_inspeccionar        = 'N',
                @i_suficiencia_legal   = 'O',
                @i_periodicidad        = 'N',
                @i_cobranza_judicial   = 'N',
                @i_abierta_cerrada     = 'A',
                @i_adecuada_noadec     = 'S',
                @i_oficina_contabiliza = @w_filial,
                @i_compartida          = 'N',
                @i_valor_compartida    = 0,
                @i_fondo_garantia      = 'N',
                @o_cod_externo         = @w_codigo_externo out
                
           if @w_return != 0 and @w_return is not null
           begin
              select @w_error  = @w_return
              goto ERROR_FIN
           end  
           Print 'Garantia [' + @w_codigo_externo + '] creada para el tramite ' + convert(varchar, @w_tramite_aux)  + ' para el cliente ' + convert(varchar, @w_ente)
           insert into #tmp_gar_cod
           (gc_tramite, gc_cod_externo)
           values
           (@w_tramite_aux, @w_codigo_externo)
        end 
        else
        begin
           select @w_codigo_externo = cu_codigo_externo
           from cob_credito..cr_gar_propuesta with(nolock), 
                cob_custodia..cu_custodia with(nolock) 
           where gp_garantia = cu_codigo_externo
           and gp_tramite  = @w_tramite_aux 
           AND cu_garante  = @w_ente
           and cu_descripcion = 'GARGPE'
           
           insert into #tmp_gar_cod
           (gc_tramite, gc_cod_externo)
           values
           (@w_tramite_aux, @w_codigo_externo)
        end
        
        --Siguiente cliente
        set @w_min_cli = @w_min_cli + 1
    end 
    

        --Asociar garantias
    select @w_min_cli = min(tg_id),
           @w_max_cli = max(tg_id)
    from #tmp_clients

    
    --Asociar de la temp de garantias
    while @w_min_cli <= @w_max_cli
    begin 
        select  @w_ente = tg_cliente, 
                @w_tramite_aux = op_tramite, 
                @w_filial = op_filial, 
                @w_oficina = op_oficina
        from #tmp_clients
        where tg_id = @w_min_cli
        
        select @w_codigo_externo = gc_cod_externo
        from #tmp_gar_cod
        where gc_tramite = @w_tramite_aux
        Print 'Garantias asociar Id [' + CONVERT(VARCHAR, @w_min_cli) + ']  tramite ' + convert(varchar, @w_tramite_aux)  + '  cliente ' + convert(varchar, @w_ente)

        select @w_garante = min(tg_cliente)
        from #tmp_gar 
        where tg_cliente != @w_ente
            
        while @w_garante is not null
        begin 
            select  @w_tramite_aux_2 = op_tramite
            from #tmp_clients
            where tg_cliente = @w_garante
            
            if @w_codigo_externo is not null and @w_codigo_externo <> ''
            begin
               --Asociar menos a el mismo
               exec @s_ssn = master..rp_ssn        
               exec @w_return =  cob_credito..sp_gar_propuesta
               @s_srv                 = @s_srv,
               @s_user                = @s_user,
               @s_term                = @s_term,
               @s_ofi                 = @s_ofi,
               @s_rol                 = @s_rol,
               @s_ssn                 = @s_ssn,
               @s_lsrv                = @s_lsrv,
               @s_date                = @s_date,
               @s_sesn                = @s_sesn,
               @t_trn                 = 21028,
               @t_timeout             = 180,
               @i_operacion           = 'I',
               @i_tramite             = @w_tramite_aux_2,
               @i_garantia            = @w_codigo_externo,
               @i_estado              = 'P',
               @i_clase               = 'A',
               @i_deudor              = @w_garante
               
               if @w_return != 0 and @w_return is not null
               begin
                     select @w_error  = @w_return
                     goto ERROR_FIN
               end 
            end
            Print 'Garantia [' + @w_codigo_externo + '] relacionada para el tramite ' + convert(varchar, @w_tramite_aux_2)  + ' para el cliente ' + convert(varchar, @w_garante)
            --Siguiente garante
            select @w_garante = min(tg_cliente)
            from #tmp_gar 
            where tg_cliente != @w_ente
            and tg_cliente > @w_garante
        end  --fin garantes
        --Siguiente cliente
        set @w_min_cli = @w_min_cli + 1
    end 
    print 'Actualizando estado tramite'
    UPDATE cob_workflow.dbo.wf_inst_proceso
    set io_campo_5 = 0 -- Fiadores generados
    where io_campo_3 = @w_tramite
    
    
    NEXT_LINE:
       print 'Siguiente registro'
       SET @w_min_inst = @w_min_inst + 1
       truncate table #tmp_gar_cod
       truncate table #tmp_gar
       truncate table #tmp_clients
end 

select @w_termina = 1
return 0

ERROR_FIN:
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
      from cobis..cl_errores 
      where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
   end
   if @w_termina = 0
   begin
      goto NEXT_LINE
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
