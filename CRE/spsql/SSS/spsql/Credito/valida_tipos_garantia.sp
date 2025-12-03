/**************************************************************************/
/*  Archivo:                valida_tipos_garantia.sp                      */
/*  Stored procedure:       sp_valida_tipos_garantia                      */
/*  Producto:               Credito                                       */
/*  Disenado por:           Carlos Obando                                 */
/*  Fecha de escritura:     05-01-2022                                    */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.”.               */
/**************************************************************************/
/*               PROPOSITO                                                */
/*  Este programa valida que las garantias agregadas coincidan con las    */
/*  permitidas                                                            */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA       AUTOR         RAZON                                       */
/*  05-01-2022  COB           Emision inicial                             */
/*  04-05-2022  COB           Se cambia la validacion de garantias previas*/
/*  05-10-2023  DMO           Se comenta llamada a sp_actualiza_op_cre    */
/**************************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_valida_tipos_garantia')
   drop proc sp_valida_tipos_garantia
go

CREATE PROCEDURE sp_valida_tipos_garantia
(
   @s_ssn                int          = null,
   @s_user               varchar(30)  = null,
   @s_sesn               int          = null,
   @s_term               varchar(30)  = null,
   @s_date               datetime     = null,
   @s_srv                varchar(30)  = null,
   @s_lsrv               varchar(30)  = null,
   @s_ofi                smallint     = null,
   @t_trn                int          = null,
   @t_debug              char(1)      = 'N',
   @t_file               varchar(14)  = null,
   @t_from               varchar(30)  = null,
   @s_rol                smallint     = null,
   @s_org_err            char(1)      = null,
   @s_error              int          = null,
   @s_sev                tinyint      = null,
   @s_msg                descripcion  = null,
   @s_org                char(1)      = null,
   @t_show_version       bit          = 0, -- Mostrar la version del programa
   @t_rty                char(1)      = null,        
   @i_operacion          char(1),
   @i_tramite            int          = 0,
   @i_motivo_msg         varchar(255) = null

)
as 
declare
   @w_tipo             varchar(30),
   @w_tipo_sup         varchar(30),
   @w_cod_cat          char(10),
   @w_cat              varchar(256),
   @w_countTG          int,
   @w_countCG          int,
   @w_countRTC         int,
   @w_equals           int = 0,
   @w_sp_name          varchar(64),
   @w_sp_msg           varchar(132),
   @w_error            int,
   @w_return           int,
   @w_operacion        varchar(256),
   @w_tramite_prev     int,
   @w_prev             int,
   @w_act              int,
   @w_equ              int,
   @w_combinacion      varchar(256)

select
@w_sp_name          = 'cob_credito..sp_valida_tipos_garantia'

if @i_operacion = 'V'
begin
   if (OBJECT_ID('tempdb.dbo.#tmp_tipo_gar','U')) is not null
   begin
      drop table #tmp_tipo_gar
   end
   create table #tmp_tipo_gar
   (tipo     varchar(30) null,
    tipo_sup varchar(30) null)
   
   insert into #tmp_tipo_gar
   select distinct cu_tipo, tc_tipo_superior
   from cob_credito..cr_gar_propuesta, 
   cob_custodia..cu_custodia, 
   cob_custodia..cu_tipo_custodia
   where gp_garantia = cu_codigo_externo
     and gp_tramite  = @i_tramite
     and tc_tipo     = cu_tipo
   
   if not exists(select 1 from #tmp_tipo_gar)
   begin
        select @w_error = 2110238
        goto ERROR_FIN
   end
   
   declare GarSup cursor for select tipo, tipo_sup from #tmp_tipo_gar
   open GarSup
   fetch next from GarSup into @w_tipo, @w_tipo_sup
   while @@fetch_status = 0
   begin
      while not isnull(@w_tipo_sup,'') = ''
      begin
         update #tmp_tipo_gar
         set
         #tmp_tipo_gar.tipo     = tc.tc_tipo,
         @w_tipo = tc.tc_tipo,
         #tmp_tipo_gar.tipo_sup = tc.tc_tipo_superior,
         @w_tipo_sup = tc.tc_tipo_superior
         from 
         cob_custodia..cu_tipo_custodia as tc
         inner join #tmp_tipo_gar as t
         on tc.tc_tipo = t.tipo_sup
         where @w_tipo = tipo
      end
   
      fetch next from GarSup into @w_tipo, @w_tipo_sup
   end
   close  GarSup
   deallocate GarSup
   
   --DMO se comenta porque ENL no usa garantias para caluclar rubros financiados
   /*delete T
   from(
   select *
   , DupRank = row_number() over (
                 partition by tipo
                 order by (select NULL)
               )
   from #tmp_tipo_gar
   ) as T
   where DupRank > 1
   
   if (OBJECT_ID('tempdb.dbo.#tmp_conv_gar','U')) is not null
   begin
      drop table #tmp_conv_gar
   end
   create table #tmp_conv_gar
   (cod_cat char(10)     null,
    cat     varchar(256) null)
   
   insert into #tmp_conv_gar
   select uf_value, uf_description
   from cob_fpm..fp_unitfunctionalityvalues
   inner join cob_fpm..fp_bankingproducts as ba on bp_product_id_fk       = ba.bp_product_id
   inner join cob_fpm..fp_bankingproducts as bb on ba.bp_product_id       = bb.bp_parentnode
   inner join cob_cartera..ca_operacion         on op_toperacion          = bb.bp_product_id
   inner join cob_fpm..fp_nodetypecategory      on bb.ntc_productcategory = ntc_productcategory_id
   where op_tramite = @i_tramite
   and uf_delete = 'N'
   if @@rowcount = 0
   begin
      select @w_error = 2110239
      goto ERROR_FIN
   end

   select @w_countTG = COUNT(1) from #tmp_tipo_gar
   
   declare GarSup cursor for select cod_cat,cat from #tmp_conv_gar
   open GarSup
   fetch next from GarSup into @w_cod_cat, @w_cat
   while @@fetch_status = 0
   begin
      select @w_countCG = COUNT(value)
      from string_split(@w_cat,'-')
   
      select @w_countRTC = COUNT(1)
      from #tmp_tipo_gar,
      string_split(@w_cat,'-') ss
      where ss.value = tipo
   
      if @w_countTG = @w_countCG and @w_countCG = @w_countRTC
      begin
         select @w_equals = 1

         exec @w_return = cob_credito..sp_actualiza_op_cre
         @s_ssn            = @s_ssn,
         @s_user           = @s_user,
         @s_sesn           = @s_sesn,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_srv            = @s_srv,
         @s_lsrv           = @s_lsrv,
         @s_rol            = @s_rol,
         @s_ofi            = @s_ofi,
         @s_org_err        = @s_org_err,
         @s_error          = @s_error,
         @s_sev            = @s_sev,
         @s_msg            = @s_msg,
         @s_org            = @s_org,
         @i_operacion      = 'U',
         @i_tramite        = @i_tramite,
         @i_grupo_contable = @w_cod_cat

         if @w_return <> 0
         begin
            select @w_error = 2110240
            goto ERROR_FIN
         end
      end
   
      fetch next from GarSup into @w_cod_cat, @w_cat
   end
   close  GarSup
   deallocate GarSup
   
   if @w_equals <> 1
   begin
        select @w_error = 2110237
        goto ERROR_FIN
   end*/
end

if @i_operacion = 'M'
begin
   select @w_operacion = ga_operacion
   from cob_credito..cr_gar_anteriores
   where ga_tramite = @i_tramite

   select @w_tramite_prev = op_tramite
   from cob_cartera..ca_operacion
   where op_banco = @w_operacion

   --ACTUALIZACION DE MENSAJE/MOTIVO
   update cob_credito..cr_tramite
   set tr_txt_razon = @i_motivo_msg
   where tr_tramite = @i_tramite

   --COMBINACION PREVIA
   if (OBJECT_ID('tempdb.dbo.#tmp_gar_prev','U')) is not null
   begin
      drop table #tmp_gar_prev
   end
   create table #tmp_gar_prev
   (tipo     varchar(30) null,
    tipo_sup varchar(30) null)

   select @w_combinacion = c.valor
   from cob_cartera..ca_operacion o,
   cob_cartera..ca_operacion_datos_adicionales a,
   cobis..cl_tabla t,
   cobis..cl_catalogo c
   where o.op_banco = @w_operacion
   and   o.op_operacion = a.oda_operacion
   and   t.tabla = 'cr_combinacion_gar'
   and   t.codigo = c.tabla
   and   c.codigo = a.oda_grupo_contable

   insert into #tmp_gar_prev (tipo)
   select value
   from string_split(@w_combinacion,'-')

   --COMBINACION NUEVA
   if (OBJECT_ID('tempdb.dbo.#tmp_gar_new','U')) is not null
   begin
      drop table #tmp_gar_new
   end
   create table #tmp_gar_new
   (tipo     varchar(30)  null,
    tipo_sup varchar(30)  null,
    cod_gar  varchar(254) null)

   --previos
   insert into #tmp_gar_new
   select distinct cu_tipo, tc_tipo_superior, gp_garantia
   from cob_credito..cr_gar_propuesta, 
   cob_custodia..cu_custodia, 
   cob_custodia..cu_tipo_custodia
   where gp_garantia = cu_codigo_externo
     and gp_tramite  = @w_tramite_prev
     and tc_tipo     = cu_tipo

   --eliminacion si es el caso
   delete from #tmp_gar_new
   where cod_gar in (select ga_gar_anterior 
                     from cob_credito..cr_gar_anteriores 
                     where ga_tramite = @i_tramite)

   --los nuevos
   insert into #tmp_gar_new
   select distinct cu_tipo, tc_tipo_superior, ga_gar_nueva
   from cob_credito..cr_gar_anteriores,
   cob_custodia..cu_custodia,
   cob_custodia..cu_tipo_custodia
   where ga_gar_nueva = cu_codigo_externo 
     and ga_tramite   = @i_tramite
     and tc_tipo      = cu_tipo

   declare GarSup cursor for select tipo, tipo_sup from #tmp_gar_new
   open GarSup
   fetch next from GarSup into @w_tipo, @w_tipo_sup
   while @@fetch_status = 0
   begin
      while not isnull(@w_tipo_sup,'') = ''
      begin
         update #tmp_gar_new
         set
         #tmp_gar_new.tipo     = tc.tc_tipo,
         @w_tipo = tc.tc_tipo,
         #tmp_gar_new.tipo_sup = tc.tc_tipo_superior,
         @w_tipo_sup = tc.tc_tipo_superior
         from 
         cob_custodia..cu_tipo_custodia as tc
         inner join #tmp_gar_new as t
         on tc.tc_tipo = t.tipo_sup
         where @w_tipo = tipo
      end
   
      fetch next from GarSup into @w_tipo, @w_tipo_sup
   end
   close  GarSup
   deallocate GarSup
   
   delete T
   from(
   select *
   , DupRank = row_number() over (
                 partition by tipo
                 order by (select NULL)
               )
   from #tmp_gar_new
   ) as T
   where DupRank > 1

   select @w_prev = COUNT(1) from #tmp_gar_prev
   select @w_act  = COUNT(1) from #tmp_gar_new
   select @w_equ  = count(1) 
   from #tmp_gar_new n,
   #tmp_gar_prev p
   where n.tipo = p.tipo

   if not (@w_prev = @w_act and @w_act = @w_equ)
   begin
      select @w_error = 2110242
      goto ERROR_FIN
   end

end

return 0

ERROR_FIN:

   exec cobis..sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_msg      = @w_sp_msg,
        @i_num      = @w_error
            
   return @w_error

go
