/************************************************************************/
/*   Archivo:             repcarciere.sp                                */
/*   Stored procedure:    sp_rep_caratula_cierre                        */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Walther Toledo Qu.                            */
/*   Fecha de escritura:  10/Septiembre/2019                            */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para los Reporte Caráturla de Cierre BC 52                */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*   FECHA           AUTOR          RAZON                               */
/*   10/Sept/2019    WTO            Emision Inicial                     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_caratula_cierre ')
   drop proc sp_rep_caratula_cierre 
go

create proc sp_rep_caratula_cierre  (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              varchar(14)       = null,
   @s_term              varchar(64) = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_show_version      bit         = 0,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               int    = null,
   @i_operacion         char(1)     = null,
   @i_banco             varchar(24)      = null,
   @i_nemonico          varchar(10)     = null,
   @i_formato_fecha     int         = null
)as
declare
   @w_sp_name           varchar(24),
   @w_op_banco          varchar(24),
   @w_tipo_oper         varchar(128),
   @w_nivel             tinyint,
   @w_fecha_ini         varchar(10),
   @w_periodo           varchar(64),
   @w_plazo             smallint,
   @w_monto_cred        money,
   @w_monto_bruto       money,
   @w_monto_aho         money,
   @w_monto_dep         money,
   @w_porc_finan        smallint,
   @w_es_refinan        varchar(2),
   @w_id_grupo          int,
   @w_nom_grupo         varchar(64),
   @w_nom_filial        varchar(64),
   @w_nom_oficial       varchar(64),
   @w_nom_oficina       varchar(64),
   @w_lug_desem         varchar(64),
   --
   @w_id_tipo_op        varchar(10),
   @w_tplazo            varchar(10),
   @w_operacion         int,
   @w_id_tramite        int,
   @w_id_oficial        smallint,
   @w_id_oficina        smallint,
   @w_simb_moneda       varchar(10),
   @w_id_moneda         tinyint,
   @w_msg               varchar(1000),
   @w_error             int,
   @w_return            int
   

select @w_sp_name = 'sp_rep_caratula_cierre'

--Versionamiento del Programa
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '1.0.0.0'
  return 0
end

if @t_trn <> 77532
begin        
   select @w_error = 151023,
          @w_msg = 'Numero de Transaccion Incorrecto: ' + @t_trn
   goto ERROR
end

select @w_operacion = op_operacion,
       @w_id_grupo = op_grupo,
       @w_fecha_ini  = convert(varchar,op_fecha_ini,103),
       @w_id_tipo_op = op_toperacion,
       @w_op_banco   = op_banco,
       @w_plazo      = op_plazo,
       @w_tplazo     = op_tplazo,
       @w_monto_cred = op_monto,
       @w_monto_bruto= op_monto,
       @w_id_tramite = op_tramite,
       @w_id_oficial = op_oficial,
       @w_id_oficina = op_oficina,
       @w_id_moneda  = op_moneda
from ca_operacion
where op_banco = @i_banco
if @@rowcount = 0
begin
   select @w_error = 710022,
          @w_msg = 'No existe operacion: ' + @i_banco
   goto ERROR
end

if @i_operacion = 'C'
begin
   select @w_tipo_oper = upper(valor )
   from cobis..cl_catalogo 
   where tabla in (
      select codigo 
      from cobis..cl_tabla 
      where tabla = 'ca_toperacion')
   and codigo = @w_id_tipo_op
   if @@rowcount = 0
   begin
      select @w_error = 141008,
             @w_msg = 'No existe tipo de operacion: ' + @w_id_tipo_op
      goto ERROR
   end

   select @w_nivel = 1, @w_porc_finan = 0, @w_es_refinan = 'NO'
   
   select @w_periodo = td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tplazo
   if @@rowcount = 0
   begin
      select @w_error = 701159,
             @w_msg = 'No existe tipo de dividendo: ' + @w_id_tipo_op
      goto ERROR
   end

   select @w_monto_dep = ci_monto_ahorro 
   from ca_ciclo 
   where ci_operacion = @w_operacion
   
   select @w_es_refinan = 'SI'
   from cob_credito..cr_tramite
   where tr_tipo = 'R'
   and tr_tramite = @w_id_tramite
   
   select @w_nom_grupo = gr_nombre
   from cobis..cl_grupo 
   where gr_grupo = @w_id_grupo

   select @w_nom_filial = fi_nombre from cobis..cl_filial
   where fi_filial = (
      select pa_tinyint
      from cobis..cl_parametro
      where pa_nemonico = 'FILIAL')
   
   select @w_nom_oficial = fu_nombre
   from cobis..cl_funcionario inner join cobis..cc_oficial
   on oc_funcionario = fu_funcionario
   and oc_oficial = @w_id_oficial
   
   select @w_nom_oficina = of_nombre
   from cobis..cl_oficina
   where of_oficina = @w_id_oficina
   
   select @w_lug_desem = of_nombre 
   from ca_desembolso inner join cobis..cl_oficina 
   on dm_oficina = of_oficina 
   and dm_operacion = @w_operacion

   select @w_simb_moneda = mo_simbolo
   from cobis..cl_moneda 
   where mo_moneda = @w_id_moneda
   if @@rowcount = 0
   begin
      select @w_error = 101045,
             @w_msg = 'No se ha configurado moneda: ' + @w_id_moneda
      goto ERROR
   end
   
   select @w_monto_dep = isnull(@w_monto_dep, 0),
          @w_monto_cred = isnull(@w_monto_cred, 0),
          @w_monto_bruto = isnull(@w_monto_bruto, 0)

   select
      @w_op_banco    op_banco   , @w_tipo_oper   tipo_oper  , @w_nivel       nivel      , @w_fecha_ini  fecha_ini , @w_periodo     periodo  ,
      @w_plazo       plazo      , @w_monto_bruto monto_bruto, @w_monto_cred  monto_cred , @w_monto_dep  monto_dep , @w_porc_finan  porc_finan ,
      @w_es_refinan  es_refinan , @w_id_grupo    id_grupo   , @w_nom_grupo   nom_grupo  , @w_nom_filial nom_filial, @w_nom_oficial nom_oficial,
      @w_nom_oficina nom_oficina, @w_lug_desem   lug_desem  , @w_simb_moneda simb_moneda
   return 0
end

if @i_operacion = 'D'
begin

   select @w_op_banco op_banco_padre, op_operacion op_operacion, op_cliente op_cliente,
          isnull(p_p_apellido + ' ','' ) +  isnull(p_s_apellido + ' ','' )+
          isnull(en_nombre + ' ','' ) +   isnull(p_s_nombre + ' ','' ) so_nombre,
          op_monto, ((op_monto*100)/@w_monto_cred) op_porcentaje, ca.valor op_rol,
          isnull(ba.so_monto_seguro,0) so_monto_seg_ba, isnull(vo.so_monto_seguro, 0) so_monto_seg_vo,
          (isnull(op_monto,0) - isnull(ba.so_monto_seguro,0) - isnull(vo.so_monto_seguro,0)) so_monto_total,
          mo_simbolo op_smb_moneda
   into #ca_oper_hijas
   from ca_operacion 
   inner join cobis..cl_ente 
   on en_ente = op_cliente  
   and op_ref_grupal = @w_op_banco
   inner join cobis..cl_cliente_grupo 
   on cg_ente = en_ente and cg_grupo = op_grupo
   
   inner join ca_seguros_op ba
   on ba.so_oper_padre = @w_operacion 
   and ba.so_operacion = op_operacion
   and ba.so_cliente = op_cliente
   and ba.so_tipo_seguro = 'B'
   left join ca_seguros_op vo
   on vo.so_oper_padre = @w_operacion 
   and vo.so_operacion = op_operacion
   and vo.so_cliente = op_cliente
   and ba.so_tipo_seguro != 'B'
   
   inner join cobis..cl_catalogo ca
   on ca.codigo = cg_rol
   inner join cobis..cl_tabla ta
   on ca.tabla = ta.codigo
   and ta.tabla = 'cl_rol_grupo'
   
   inner join cobis..cl_moneda
   on mo_moneda = op_moneda
   
   
   select op_banco_padre, op_operacion, op_cliente,
          so_nombre, op_monto , op_porcentaje , op_rol,
          so_monto_seg_ba, so_monto_seg_vo,so_monto_total
           ,     op_smb_moneda
   from #ca_oper_hijas
   where op_banco_padre = @w_op_banco

   return 0
end


return 0

ERROR:
exec @w_return = cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error,
@i_msg    = @w_msg

return @w_error


go