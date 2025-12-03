/************************************************************************/
/*  Archivo:                estado_cliente.sp                           */
/*  Stored procedure:       sp_estado_cliente                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_estado_cliente')
    drop proc sp_estado_cliente
go

create proc sp_estado_cliente(

   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_ssn               int         = null,
   @s_sesn              int              = null,
   @s_term              descripcion = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @i_cliente           int,
   @i_mala_ref          char(1),
   @i_refcod            catalogo,            --situacion cliente
   @i_refdesc           varchar(255) = null
)
as
declare
   @w_return            int,           /* VALOR QUE RETORNA */
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
   @w_basura            tinyint,
   @w_origen            descripcion,
   @w_ced_ruc           numero,
   @w_nombre            descripcion,
   @w_fecha_proc        datetime,
   @w_subtipo           char(1),
   @w_p_p_apellido      varchar(16),
   @w_p_s_apellido      varchar(16),
   @w_tipo_ced          char(2),
   @w_sexo              sexo,
   @w_largo             varchar(254),
   @w_cont              int,
   @w_nombre_func       descripcion,      /* NOMBRE DEL FUNCIONARIO */
   @o_codigo_sig        int ,
   @w_refinh            catalogo,      --SBU situacion cliente
   @w_desc_calif        descripcion,
   @w_calificacion      catalogo,
   @w_situacion         catalogo,
   @w_rfi_sit           catalogo,
   @w_sitcs             catalogo,
   @w_refcod            catalogo,
   @w_refdesc           varchar(255),
   @w_rowcount          int


/* NOMBRE DEL SP */
select @w_sp_name = 'sp_estado_cliente'

/* FECHA DE PROCESO */
select @w_fecha_proc = fp_fecha
from   cobis..ba_fecha_proceso

/* SELECCION DE PARAMETROS */
select @w_origen = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CRE'
and    pa_nemonico = 'REFORI' --lpo

if @@rowcount = 0
begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101084
   return 1
end

/* SELECCION DE PARAMETROS */
select @w_sitcs = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'SITCS'
and    pa_producto = 'CRE'

if @@rowcount = 0
begin
   /* No existe valor de parametro */
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 2101084
   return 1
end

/* DATOS DEL CLIENTES PARA LA INSERCION */
select @w_ced_ruc = en_ced_ruc,
       @w_nombre = en_nombre,
       @w_subtipo = en_subtipo,
       @w_p_p_apellido = p_p_apellido,
       @w_p_s_apellido = p_s_apellido,
       @w_tipo_ced = en_tipo_ced,
       @w_largo = en_nomlar,
       @w_cont = isnull(en_cont_malas, 0),
       @w_refinh = en_emala_referencia,            --SBU situacion cliente
       @w_calificacion = en_calificacion,
       @w_sexo         = p_sexo
from  cobis..cl_ente
where  en_ente = @i_cliente

select @w_desc_calif = b.valor
from  cobis..cl_tabla a, cobis..cl_catalogo b
where   @w_calificacion = b.codigo
and    a.codigo = b.tabla
and    a.tabla = 'cr_calificacion'


if @i_mala_ref = 'S'
begin

   begin tran

      exec cobis..sp_cseqnos
           @t_from     = @w_sp_name,
           @i_tabla    = 'cl_refinh',
           @o_siguiente= @o_codigo_sig out

--      if not exists --lpo
      if exists(select 1
                    from cobis..cl_refinh
                    where in_ced_ruc = convert(varchar(13),@w_ced_ruc)
                    and  in_tipo_ced = @w_tipo_ced
                    and  in_estado = @i_refcod )
         select @w_basura = 1
      else
      begin
         update cobis..cl_ente
         set en_emala_referencia = @i_refcod,
             en_mala_referencia = @i_mala_ref,      --SBU situacion cliente
             en_cont_malas = isnull(en_cont_malas,0) + 1
         where en_ente = @i_cliente

         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from  = @w_sp_name,
            @i_num   = 2105001
            return 1
         end

         insert into cobis..cl_refinh(
         in_codigo,        in_documento,    in_ced_ruc,
         in_nombre,        in_fecha_ref,    in_origen,
         in_observacion,   in_fecha_mod,    in_subtipo,
         in_p_p_apellido,  in_p_s_apellido, in_tipo_ced,
         in_nomlar,        in_estado)
         values (
         @o_codigo_sig,       0,               convert(varchar(13),@w_ced_ruc),
         @w_nombre,           @w_fecha_proc,   @w_origen,
         @i_refdesc,          @w_fecha_proc,   @w_subtipo,
         @w_p_p_apellido,     @w_p_s_apellido, @w_tipo_ced,
         @w_largo,            @i_refcod)

         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from  = @w_sp_name,
            @i_num   = 2103001
            return 1
         end
      end
   commit tran
end
else
begin   --SI REF = 'N'
   if @w_cont <> 0
      select @w_cont = @w_cont - 1
   else
      select @w_cont = 0

   select @w_situacion = codigo,      --SBU situacion cliente
          @i_refdesc   = isnull(@i_refdesc, descripcion_sib)
   from cr_corresp_sib
   where codigo_sib = @i_refcod
   and tabla = 'T15'

   select @w_rfi_sit = codigo_sib
   from cr_corresp_sib
   where codigo = @w_situacion
   and tabla = 'T14'


   begin tran                  --SBU situacion cliente
      if @w_refinh = @w_rfi_sit
      begin
         update cobis..cl_ente
         set en_emala_referencia = null,
             en_cont_malas = @w_cont,
             en_mala_referencia = @i_mala_ref
         where en_ente = @i_cliente

         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from  = @w_sp_name,
            @i_num   = 2105001
            return 1
         end
      end
      else
      begin
         update cobis..cl_ente
         set en_cont_malas = @w_cont
         where en_ente = @i_cliente

         if @@error != 0
         begin
            exec cobis..sp_cerror
            @t_from  = @w_sp_name,
            @i_num   = 2105001
            return 1
         end
      end

      select @w_nombre_func = fu_nombre
      from   cobis..cl_funcionario
      where  fu_login = @s_user

      select
      @w_nombre_func = isnull(@w_nombre_func,'crebatch'),
      @w_desc_calif = isnull(@w_desc_calif, 'NO CALIFICADO')


      select @w_refcod = case
                         when datalength(@i_refcod) = 2 then '0'+@i_refcod 
                         when datalength(@i_refcod) = 1 then '00'+@i_refcod 
                         else @w_refcod end
      if exists (select 1
      from cobis..cl_mercado
      where me_ced_ruc  = convert(varchar(13),@w_ced_ruc)
      and   me_tipo_ced = @w_tipo_ced
      and   me_estado   = @w_refcod ) begin
         select @w_basura = 1
      end else
      begin
         if @w_situacion = @w_sitcs begin
            select
            @w_origen     = 'CASTIGO DE CARTERA',
            @w_desc_calif = 'E3' 

            select @w_refdesc = op_banco
            from   cob_cartera..ca_operacion, cob_cartera..ca_estado
            where  op_estado = es_codigo
            and    es_procesa = 'S'
            order by op_estado desc 
         end else begin
            select 
            @w_refcod  = @i_refcod,
            @w_refdesc = @i_refdesc
         end

         exec @w_return = cobis..sp_mercado_dml
         @s_date         = @s_date,
         @s_user         = @s_user,
         @s_ssn          = @s_ssn,
         @s_term         = @s_term,
         @s_srv          = @s_srv,
         @i_operacion    = 'I',
         @t_trn          = 1285,
         @i_documento    = 0,
         @i_ced_ruc      = @w_ced_ruc,
         @i_nombre       = @w_nombre,
         @i_origen       = @w_origen,
         @i_observacion  = @w_refdesc,
         @i_calificador  = @s_user ,
         @i_calificacion = @w_desc_calif,
         @i_fecharef     = @s_date,
         @i_subtipo      = @w_subtipo,
         @i_tipo_ced     = @w_tipo_ced,
         @i_p_apellido   = @w_p_p_apellido,
         @i_s_apellido   = @w_p_s_apellido,
         @i_estadorm     = @w_refcod,
         @i_sexo         = @w_sexo

         if @w_return <> 0 or  @@error != 0 return isnull(@w_return, 1)
      end

      delete cobis..cl_refinh
      where in_ced_ruc = convert(varchar(13),@w_ced_ruc)
      and in_estado = @w_rfi_sit

      if @@error != 0
      begin
         exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2107001
         return 1
      end
   commit tran
end


return 0

GO

