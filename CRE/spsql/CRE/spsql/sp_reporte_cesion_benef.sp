/********************************************************************/
/*   NOMBRE LOGICO:        sp_cesion_benef                          */
/*   NOMBRE FISICO:        sp_cesion_benef.sp                       */
/*   BASE DE DATOS:        cob_credito                              */
/*   PRODUCTO:             Credito                                  */
/*   DISENADO POR:         B. Duenas.                               */
/*   FECHA DE ESCRITURA:   06-Feb-2023                              */
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
/*  Este stored procedure permite consultar informacion del         */
/*   beneficiario                                                   */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   06-Feb-2023        B. Duenas.       Emision Inicial - S762876  */
/*   30-Mar-2023        P. Jarrin.       Se agrega orden - S801301  */
/*   16-Nov-2023        B. Duenas.       R219497:Se agrega apellido */
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_cesion_benef')
   drop proc sp_cesion_benef
go

CREATE proc sp_cesion_benef (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_tramite              int             = null,
    @i_tipo                 char(1)         = null,
    @i_cliente              int             = null,
    @i_operacion            char(1)                -- Opcion con que se ejecuta el programa
)
as
declare @w_sp_name              varchar(32),
        @w_aseguradora          varchar(150),
        @w_seguro               varchar(25),
        @w_ente                 int,
        @w_operacion            varchar(20),
        @w_tramite              varchar(20),
        @w_grupal               char(1),
        @w_filial               varchar(200),
        @w_fecha_liq            varchar(10),
        @w_fecha_letras         varchar(100),
        @w_monto                varchar(100),
        @w_lugar                varchar(150),
        @w_error                int,
        @w_nombre               varchar(150),
        @w_dui                  varchar(20),
        @w_monto_poliza         varchar(20)

declare @w_participantes as table(
cod           int           null,
lugar         varchar(100)  null,
fecha_letras  varchar(100)  null,
filial        varchar(100)  null,
monto         varchar(100)  null,
nombre        varchar(150)  null,
dui           varchar(20)   null
)

declare @w_beneficiarios as table(
num           int           null,
nombre        varchar(100)  null,
edad          int           null,
parentesco    varchar(150)  null,
porcentaje    int           null,
ente          int           null
)  
        
select @w_sp_name = 'sp_cesion_benef'
if @t_trn <> 21864
begin
   select @w_error = 151051
   goto ERROR
end

select  @w_monto_poliza = pa_char from cobis..cl_parametro where pa_nemonico = 'MONPOL' and pa_producto = 'CRE'
if (@w_monto_poliza is null)
begin
    select @w_error = 609327
    goto ERROR
end

select  @w_aseguradora = pa_char from cobis..cl_parametro where pa_nemonico = 'NOMSEG' and pa_producto = 'CRE'
if (@w_aseguradora is null)
begin
    select @w_error = 609327
    goto ERROR
end
select  @w_seguro = pa_char from cobis..cl_parametro where pa_nemonico = 'SEGCOL' and pa_producto = 'CRE'
if (@w_seguro is null )
begin
    select @w_error = 609327
    goto ERROR
end


if(@i_tramite is null)
begin
    select @w_error = 2110256
    goto ERROR
end


if(@i_operacion = 'Q')
begin

    IF OBJECT_ID('tempdb..#tmp_participantes') IS NOT NULL
    drop table #tmp_participantes

    create table #tmp_participantes
    (
        cliente    int,
        tramite    int null,
        rol        char(1),
        orden      smallint 
    )

    if(@i_tipo = 'D')
    begin
       if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
       begin
           insert into #tmp_participantes
           select tg_cliente, 
                  op_tramite, 
                  (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = tg_cliente and cg_grupo = tg_grupo),
                  0
                 from cob_credito..cr_tramite_grupal 
                inner join cob_cartera..ca_operacion on tg_operacion = op_operacion
                where tg_tramite = @i_tramite and tg_participa_ciclo = 'S'
                order by tg_cliente
                   
           update #tmp_participantes
              set orden = 1
            where rol = 'P'

           update #tmp_participantes
              set orden = 2
            where rol not in ('P' , 'M')

           update #tmp_participantes
              set orden = 3
            where rol = 'M'
             
           declare cur_participantes cursor read_only for select cliente, tramite from #tmp_participantes order by orden
       end
       else
       begin
           if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
           begin
               select @w_error = 2110152
               goto ERROR
           end
           declare cur_participantes cursor read_only for ( select de_cliente, de_tramite 
                                                            from cob_credito..cr_deudores 
                                                            where de_tramite = @i_tramite)
       end     
       
       open cur_participantes
        fetch cur_participantes into @w_ente, @w_tramite
        while (@@fetch_status = 0)
        begin
             /* Buscar el numero de operacion */
             select @w_operacion = op_operacion
             from cob_cartera..ca_operacion
             where op_tramite = @w_tramite
             if @@rowcount = 0
             begin
                select @w_error = 2110185
                goto ERROR
             end
             select @w_lugar             = (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
                    @w_fecha_liq         = convert(varchar, FORMAT(ca.op_fecha_liq, 'dd/MM/yyyy')),
                    @w_filial            = cf.fi_nombre,
                    @w_monto             = @w_monto_poliza,
                    @w_nombre            = case when ce.en_nomlar not like '%' + ce.p_c_apellido + '%' then ce.en_nomlar + ' ' + isnull(ce.p_c_apellido,'') --AGREGAR CUANDO NO ESTE
                                           else ce.en_nomlar --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
                                           end,
                    @w_dui               = ce.en_ced_ruc
             from cob_cartera..ca_operacion ca,
                  cobis..cl_oficina co,
                  cobis..cl_filial cf,
                  cobis..cl_ente ce
             where ca.op_operacion = @w_operacion and
             ca.op_oficina   = co.of_oficina and
                   co.of_filial    = cf.fi_filial AND
                   ca.op_cliente   = ce.en_ente
                          
            exec cob_credito..sp_conv_numero_letras
                @t_trn  = 9490,
                @i_opcion  = 7,
                @i_fecha   = @w_fecha_liq,
                @o_letras  = @w_fecha_letras out /* valor en letras */ 
       
                    
            insert into @w_participantes 
            select en_ente,
                   @w_lugar,
                   @w_fecha_letras,
                   @w_filial,
                   @w_monto,
                   @w_nombre,
                   @w_dui
            from cobis..cl_ente 
            where en_ente = @w_ente 
            if @@error <> 0 
            begin
                select @w_error = 2610180
                goto ERROR
                close cur_participantes
                deallocate cur_participantes
            end
            
            fetch cur_participantes into @w_ente, @w_tramite
        end
        close cur_participantes
        deallocate cur_participantes
        
        select 'lugar'       = trim(lugar),
               'fechaLetras' = trim(fecha_letras),
               'filial'      = trim(filial),
               'monto'       = trim(monto),
               'nombre'      = trim(nombre),
               'dui'         = trim(dui),
               'aseguradora' = trim(@w_aseguradora),
               'ente'        = cod
        from @w_participantes
    end
    
    if @i_tipo = 'B'
    begin
       if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
       begin
           insert into #tmp_participantes
           select tg_cliente, 
                  op_tramite, 
                  (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = tg_cliente and cg_grupo = tg_grupo),
                  0
                 from cob_credito..cr_tramite_grupal 
                inner join cob_cartera..ca_operacion on tg_operacion = op_operacion
                where tg_tramite = @i_tramite and tg_participa_ciclo = 'S'
                order by tg_cliente
                   
           update #tmp_participantes
              set orden = 1
            where rol = 'P'

           update #tmp_participantes
              set orden = 2
            where rol not in ('P' , 'M')

           update #tmp_participantes
              set orden = 3
            where rol = 'M'
             
           declare cur_participantes cursor read_only for select cliente, tramite from #tmp_participantes order by orden
       end
       else
       begin
           if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
           begin
               select @w_error = 2110152
               goto ERROR
           end
           declare cur_participantes cursor read_only for ( select de_cliente, de_tramite 
                                                            from cob_credito..cr_deudores 
                                                            where de_tramite = @i_tramite)
       end     
       
       open cur_participantes
        fetch cur_participantes into @w_ente, @w_tramite
        while (@@fetch_status = 0)
        begin
             /* Buscar el numero de operacion */
             select @w_operacion = op_operacion
             from cob_cartera..ca_operacion
             where op_tramite = @w_tramite
             if @@rowcount = 0
             begin
                select @w_error = 2110185
                goto ERROR
             end
             
             if exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_nro_operacion = @w_tramite * -1) 
             or
             exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_nro_operacion = @w_operacion)
             begin
                insert into @w_beneficiarios 
                select distinct bs_secuencia, 
                       upper(trim(isnull(bs_nombres, ''))) + ' ' + upper(trim(isnull(bs_apellido_paterno, '')))+ ' ' + upper(trim(isnull(bs_apellido_materno, ''))), 
                       datediff(year, bs_fecha_nac, getdate()),
                       (select valor from cobis.dbo.cl_catalogo cc WHERE tabla = 
                       (select codigo from cobis.dbo.cl_tabla where tabla = 'cl_parentesco_beneficiario')
                       and codigo = bs_parentesco),
                       bs_porcentaje,
                       bs_ente
                from cobis.dbo.cl_beneficiario_seguro cbs 
                where bs_ente = @w_ente
                and bs_tramite = @w_tramite
                and bs_seguro = @w_seguro
                if @@error <> 0 
                begin
                    close cur_participantes
                    deallocate cur_participantes
                    select @w_error = 2610180
                    goto ERROR
                end
             end
            fetch cur_participantes into @w_ente, @w_tramite
        end
        close cur_participantes
        deallocate cur_participantes
        select 'num'              = num,
               'nombre'           = trim(nombre),
               'edad'             = edad,
               'parentesco'       = trim(parentesco),
               'porcentaje'       = porcentaje,
               'ente'             = convert(varchar,ente)
        from @w_beneficiarios
        order by num asc
    end
end 

return 0

ERROR:
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
go
