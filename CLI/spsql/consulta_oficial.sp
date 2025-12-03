/********************************************************************/
/*  Archivo:                         consulta_oficial.sp            */
/*  Stored procedure:                sp_consulta_oficial            */
/*  Base de datos:                   cobis                          */
/*  Producto:                        Clientes                       */
/*  Disenado por:                    BDU                            */
/*  Fecha de escritura:              14-06-2024                     */
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
/*   sitio, queda expresamente prohibido sin el debido              */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada y por lo tanto, derivará en acciones legales civiles   */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                          PROPOSITO                               */
/*  SP para consultar informacion de oficiales y reasignar a otro   */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                       */
/*      14/06/24        BDU      R235692 - Emision Inicial          */
/*      22/08/24        BDU      R235692 - Se cambia columna        */
/*      27/11/24        GRO      R246371 reachazo de solic estado 6 */
/*      23/12/24        BDU      R246371 Mejora Query               */
/********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_consulta_oficial')
   drop proc sp_consulta_oficial
go
CREATE PROCEDURE sp_consulta_oficial (
        @s_ssn                  int             = null,
        @s_user                 login           = null,
        @s_term                 varchar(32)     = null,
        @s_sesn                 int             = null,
        @s_culture              varchar(10)     = null,
        @s_date                 datetime        = null,
        @s_srv                  varchar(30)     = null,
        @s_lsrv                 varchar(30)     = null,
        @s_rol                  smallint        = NULL,
        @s_org_err              char(1)         = NULL,
        @s_error                int             = NULL,
        @s_sev                  tinyint         = NULL,
        @s_msg                  descripcion     = NULL,
        @s_org                  char(1)         = NULL,
        @s_ofi                  smallint        = NULL,
        @t_debug                char(1)         = 'N',
        @t_file                 varchar(14)     = null,
        @t_from                 varchar(30)     = null,
        @t_trn                  int             = null,
        @t_show_version         bit             = 0,     -- Mostrar la version del programa
        @i_operacion            char            = null,  -- Valor de la operacion a realizar
        @i_tipo                 char            = null,  -- Diferenciador de pregunta o respuesta
        @i_oficial              int             = NULL,  -- Código de oficial que se va a consultar informacion
        @i_oficial_asignar      int             = null,  -- Código de oficial al que se va a reasignar la data
        @i_prospectos           varchar(max)    = null,  -- Códigos de los prospectos a transmitir
        @i_grupos               varchar(max)    = null   -- Códigos de los grupos a transmitir
        )
as
declare 
        @w_sp_name          varchar(32),
        @w_return           int,
        @w_date             datetime,
        @w_delimiter        varchar(1) 
        
select  @w_delimiter = '|',
        @w_date      = getdate()
     

if @i_operacion = 'Q' --Consulta
begin
   select op_grupo as 'grupo'
   into #tmp_oper_grupal
   from cob_cartera.dbo.ca_operacion with(nolock)
   where op_grupal = 'S'
   and op_ref_grupal is null
   
   
   select cg_ente as 'miembro'
   into #tmp_miembros
   from cobis..cl_cliente_grupo with(nolock)
   where cg_estado = 'V'
   

   if @i_tipo = 'O' --operaciones
   begin
      SELECT operacion = CASE 
                             WHEN co.op_estado = 99 AND co.op_ref_grupal IS NULL THEN wip1.io_codigo_alterno
                             WHEN co.op_estado = 99 AND co.op_ref_grupal IS NOT NULL THEN ''
                             ELSE co.op_banco 
                         END,
             [op padre] =  CASE 
                               WHEN co.op_estado = 99 AND co.op_ref_grupal IS NOT NULL THEN wip2.io_codigo_alterno
                               ELSE cox.op_banco 
                           END, 
              producto = co.op_toperacion,
              estado = ce.es_descripcion
      FROM cob_cartera.dbo.ca_operacion co with (nolock)
      LEFT JOIN cob_cartera.dbo.ca_operacion cox with (nolock) ON cox.op_banco = co.op_ref_grupal
      INNER JOIN cob_cartera.dbo.ca_estado ce with (nolock) ON ce.es_codigo = co.op_estado
      LEFT JOIN cob_workflow.dbo.wf_inst_proceso wip1 with (nolock) ON wip1.io_campo_3 = co.op_tramite
      LEFT JOIN cob_workflow.dbo.wf_inst_proceso wip2 with (nolock) ON wip2.io_campo_3 = cox.op_tramite
      WHERE co.op_oficial = @i_oficial
      AND co.op_estado NOT IN (3, 6) -- Se muestran operaciones en estado no vigente y crédito
   end
   
   if @i_tipo = 'C' --Clientes
   begin
      select ce.en_ente, ce.en_nomlar, ccg.cg_grupo, cg2.gr_nombre
      from cobis.dbo.cl_ente ce 
      left join cobis.dbo.cl_cliente_grupo ccg on ccg.cg_ente = en_ente and ccg.cg_estado = 'V'
      left join cobis.dbo.cl_grupo cg2 on cg2.gr_grupo = ccg.cg_grupo and cg2.gr_estado = 'V'
      where en_oficial = @i_oficial
      and en_subtipo = 'P'
      and en_ente in (select cli.cl_cliente from cobis.dbo.cl_cliente cli)
   end
   
   if @i_tipo = 'P' --Prospectos
   begin
      select ce.en_ente, ce.en_nomlar, ccg.cg_grupo, cg2.gr_nombre
      from cobis.dbo.cl_ente ce 
      left join cobis.dbo.cl_cliente_grupo ccg on ccg.cg_ente = en_ente and ccg.cg_estado = 'V'
      left join cobis.dbo.cl_grupo cg2 on cg2.gr_grupo = ccg.cg_grupo and cg2.gr_estado = 'V'
      where en_oficial = @i_oficial
      and en_subtipo = 'P'
      and en_ente not in (select cli.cl_cliente from cobis.dbo.cl_cliente cli)
      and en_ente not in (select miembro from #tmp_miembros)
   end
   
   if @i_tipo = 'G' --Grupos
   begin
      select gr_grupo, gr_nombre
      from cobis.dbo.cl_grupo cg 
      where cg.gr_oficial = @i_oficial
      and cg.gr_estado = 'V'
      and cg.gr_grupo not in (select grupo from #tmp_oper_grupal)
   end
end

if @i_operacion = 'R' --Reasignar
begin
   
   select ob_codigo as 'gr_cod'
   into #tmp_grupos_pendientes
   from cl_act_ofi_batch
   where ob_tipo = 1
   and ob_fecha_act is null
   
   
   select ob_codigo as 'en_cod'
   into #tmp_clientes_pendientes
   from cl_act_ofi_batch
   where ob_tipo = 0
   and ob_fecha_act is null
   
   
   create table #reasignacion_cliente (
   codigo       int       null,
   ofi_nuevo    int       null,
   es_grupo     bit       null
   )
   
   
   DECLARE @Start INT, @End INT
   if @i_prospectos is not null and @i_prospectos != ''
   begin
      SET @Start = 1
      SET @End = CHARINDEX(@w_delimiter, @i_prospectos, @Start)
      WHILE @Start < LEN(@i_prospectos) + 1
      BEGIN
          IF @End = 0 
              SET @End = LEN(@i_prospectos) + 1
          insert into #reasignacion_cliente(codigo, ofi_nuevo, es_grupo)
          select convert(int, (SUBSTRING(@i_prospectos, @Start, @End - @Start))), @i_oficial_asignar, 0
          SET @Start = @End + 1
          SET @End = CHARINDEX(@w_delimiter, @i_prospectos, @Start)
      END
   end
   
   if @i_grupos is not null and @i_grupos != ''
   begin
      SET @Start = 1
      SET @End = CHARINDEX(@w_delimiter, @i_grupos, @Start)
      WHILE @Start < LEN(@i_grupos) + 1 
      BEGIN
          IF @End = 0 
              SET @End = LEN(@i_grupos) + 1
          insert into #reasignacion_cliente(codigo, ofi_nuevo, es_grupo)
          select convert(int, (SUBSTRING(@i_grupos, @Start, @End - @Start))), @i_oficial_asignar, 1
          SET @Start = @End + 1
          SET @End = CHARINDEX(@w_delimiter, @i_grupos, @Start)
      END
   end
   
   if exists(select 1 from #reasignacion_cliente where es_grupo = 0)
   begin
      --Insertar registros nuevos excluyendo los que ya existen
      insert into cl_act_ofi_batch (
          ob_codigo,  ob_tipo,      ob_ofi_nuevo,
          ob_ofi_ant, ob_fecha_ing, ob_fecha_act)
      select codigo, es_grupo, @i_oficial_asignar,
             en_oficial, @w_date, null
      from #reasignacion_cliente
      inner join cobis..cl_ente on en_ente = codigo
      where es_grupo = 0
      and codigo not in (select en_cod from #tmp_clientes_pendientes)
      
   end
   
   if exists(select 1 from #reasignacion_cliente where es_grupo = 1)
   begin
   
      --Insertar registros nuevos excluyendo los que ya existen
      insert into cl_act_ofi_batch (
          ob_codigo,  ob_tipo,      ob_ofi_nuevo,
          ob_ofi_ant, ob_fecha_ing, ob_fecha_act)
      select codigo, es_grupo, @i_oficial_asignar,
             gr_oficial, @w_date, null
      from #reasignacion_cliente tmp
      inner join cobis..cl_grupo on gr_grupo = codigo
      where es_grupo = 1
      and codigo not in (select gr_cod from #tmp_grupos_pendientes)
      
   end
   
      --Actualizar el oficial a actualizar de los pendientes
      update cobis..cl_act_ofi_batch
      set ob_ofi_nuevo = @i_oficial_asignar
      from #reasignacion_cliente
      where ob_codigo = codigo
      and ob_tipo = es_grupo
      and ob_fecha_act is null
end

return 0

ERROR:
   exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
      
      return @w_return
    
go
        