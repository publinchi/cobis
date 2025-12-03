/********************************************************************/
/*   NOMBRE LOGICO:          sp_crea_fiador_grp                     */
/*   NOMBRE FISICO:          sp_crea_fiador_grp.sp                  */
/*   BASE DE DATOS:          cob_credito                            */
/*   PRODUCTO:               Credito                                */
/*   DISENADO POR:           P. Jarrin                              */
/*   FECHA DE ESCRITURA:     20-01-2023                             */
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
/*                     PROPOSITO                                    */
/*   Proceso para establecer fiadores para un credito grupal        */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   20-01-2023        P. Jarrin.       Emision Inicial - S766352   */
/*   20-07-2023        D. Morales       S864458: Optimizacion       */
/*   01-09-2023        P. Jarrin.       B895467-R213300-Optimizacion*/
/*   22-09-2023        B. Dueñas.       R215919 Optimizacion        */
/*   27-09-2023        B. Dueñas.       R215919 Agregar logica batch*/
/*   27-11-2023        M. Cabay.        Se agrega registro tabla ts */
/*                                      solo por grupo              */
/*   30-11-2023        B. Dueñas.       Se valida codigo externo    */
/*   01-12-2023        B. Dueñas.       R220601-Agregar garantias   */
/*                                      existentes                  */
/*   12-12-2023        B. Dueñas.       R221319-Ajustar logica      */
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_crea_fiador_grp')
   drop proc sp_crea_fiador_grp
go

CREATE PROCEDURE sp_crea_fiador_grp (
        @s_ssn                           int          = null,
        @s_user                          login        = null,
        @s_term                          varchar(32)  = null,
        @s_sesn                          int          = null,
        @s_culture                       varchar(10)  = 'NEUTRAL',
        @s_date                          datetime     = null,
        @s_srv                           varchar(30)  = null,
        @s_lsrv                          varchar(30)  = null,
        @s_rol                           smallint     = NULL,
        @s_org_err                       char(1)      = NULL,
        @s_error                         int          = NULL,
        @s_sev                           tinyint      = NULL,
        @s_msg                           descripcion  = NULL,
        @s_org                           char(1)      = NULL,
        @s_ofi                           smallint     = NULL,
        @t_rty                           char(1)      = null,
        @t_debug                         char(1)      = 'N',
        @t_file                          varchar(14)  = null,
        @t_from                          varchar(30)  = null,
        @t_trn                           int          = null,
        @t_show_version                  bit          = 0,
        @t_timeout                       int          = 120,
        @i_id_inst_proc                  int,
        @i_id_inst_act                   int          = null,
        @i_id_empresa                    int          = null,
        @i_operacion                     char(1)      = null, 
        @o_id_resultado                  smallint     out      --1 Ok --2 Devolver
        )
as
declare 
        @w_sp_name                   varchar(32),
        @w_sp_msg                    varchar(100),
        @w_return                    int,
        @w_error                     int,
        @w_tramite                   int,
        @w_tramite_aux               int,
        @w_tramite_aux_2             int,
        @w_filial                    int,
        @w_oficina                   int,
        @w_tipo_personal             varchar(10),
        @w_ente                      int,
        @w_garante                   int,
        @w_codigo_externo            varchar(64),
        @w_banco_padre               varchar(24),
        @w_min_cli                   int,
        @w_max_cli                   int,
        @w_min_gar                   int,
        @w_max_gar                   int,
        @w_start_1                   datetime,
        @w_start_2                   datetime,
        @w_ms_1                      int,
        @w_ms_2                      int,
        @w_num_integrantes           int,
        @w_grupo                     int
        
select  @w_sp_name  = 'sp_crea_fiador_grp',
        @w_ente     = 0,
        @w_garante  = 0,
        @w_num_integrantes = 0

select @w_tipo_personal = pa_char
  from cobis..cl_parametro
 where pa_producto = 'GAR'
   and pa_nemonico = 'GARGPE' 
 
select @w_tramite = io_campo_3
 from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

select @w_grupo = io_campo_1
 from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc


if exists (select 1 from cob_credito..cr_tramite_grupal with(nolock) where tg_tramite = @w_tramite)
begin      
    
    select @w_num_integrantes = count(tg_cliente)
    from cob_credito..cr_tramite_grupal with(nolock)
    where tg_tramite = @w_tramite 
    and tg_participa_ciclo = 'S'
    
    if @w_num_integrantes > 15
    begin
       goto ADD_BATCH_OP
    end
    
    select @w_start_1 = getdate()
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

    insert into #tmp_gar
    select tg_cliente
    from #tmp_clients 
    order by tg_cliente
   
        --Crear garantias
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
        --Print 'Garantias crear Id [' + CONVERT(VARCHAR, @w_min_cli) + ']  tramite ' + convert(varchar, @w_tramite_aux)  + '  cliente ' + convert(varchar, @w_ente)
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
                @s_ofi                 = @s_ofi,
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
           --Print 'Garantia [' + @w_codigo_externo + '] creada para el tramite ' + convert(varchar, @w_tramite_aux)  + ' para el cliente ' + convert(varchar, @w_ente)
           
           insert into #tmp_gar_cod
           (gc_tramite, gc_cod_externo)
           values
           (@w_tramite_aux, @w_codigo_externo)
        end 
        else
        begin
           select @w_codigo_externo = cu_codigo_externo
           from cob_credito..cr_gar_propuesta with(nolock), cob_custodia..cu_custodia with(nolock) 
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
    
    select @w_ms_1 = datediff(ms, @w_start_1, getdate())
    --Print 'Termina creacion de garantias en ' + convert(varchar, @w_ms_1)+ ' ms'

    select @w_start_2 = getdate()
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
        --Print 'Garantias asociar Id [' + CONVERT(VARCHAR, @w_min_cli) + ']  tramite ' + convert(varchar, @w_tramite_aux)  + '  cliente ' + convert(varchar, @w_ente)+ '  GAR ' + convert(varchar, @w_codigo_externo)

        select @w_garante = min(tg_cliente)
        from #tmp_gar 
        where tg_cliente != @w_ente
        
        if @s_ssn is null
         begin
           exec @s_ssn = master..rp_ssn  
         end
         
        while @w_garante is not null
        begin 
            select  @w_tramite_aux_2 = op_tramite
            from #tmp_clients
            where tg_cliente = @w_garante
            
            if @w_codigo_externo is not null and @w_codigo_externo <> ''
            begin
               --Asociar menos a el mismo
               exec @w_return = cob_credito..sp_gar_propuesta
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
               @i_deudor              = @w_garante,
               @i_canal               = 2 --Se asigna canal workflow
               
               if @w_return != 0 and @w_return is not null
               begin
                     select @w_error  = @w_return
                     goto ERROR_FIN
               end 
            end
            --Print 'Garantia [' + @w_codigo_externo + '] relacionada para el tramite ' + convert(varchar, @w_tramite_aux_2)  + ' para el cliente ' + convert(varchar, @w_garante)
            --Siguiente garante
            select @w_garante = min(tg_cliente)
            from #tmp_gar 
            where tg_cliente != @w_ente
            and tg_cliente > @w_garante
        end  --fin garantes
        --Siguiente cliente
        set @w_min_cli = @w_min_cli + 1
    end 
    select @w_ms_2 = datediff(ms, @w_start_2, getdate())
    --Print 'Termina asociacion de garantias en ' + convert(varchar, @w_ms_2)+ ' ms'
end 

--Inserto información para auditoria
if @w_codigo_externo is not null
begin
  insert into ts_gar_propuesta
       values ( @s_ssn, '21028', 'N', @s_date, @s_user, @s_term, @s_ofi,'cr_gar_propuesta', @s_lsrv,
                @s_srv, @w_tramite_aux,  @w_codigo_externo,@s_date, null,null, 'A', @w_grupo,'P', null,
                null, @s_date,null, ISNULL(@w_min_cli,0))--Numero de clientes insertados para el grupo @w_grupo

end

select @o_id_resultado = 1 --Ok

return 0

ADD_BATCH_OP: --Actualizar estado a pendiente a ser tratada por batch generador de fiadores
   --Print 'Pendiente de crear fiadores'
   UPDATE cob_workflow.dbo.wf_inst_proceso
   set io_campo_5 = 1 --Pendiente a generar fiadores
   where io_campo_3 = @w_tramite
   select @o_id_resultado = 1 --Ok
   return 0


ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_error  

select @o_id_resultado = 2 --Devolver   
return @w_error

go
