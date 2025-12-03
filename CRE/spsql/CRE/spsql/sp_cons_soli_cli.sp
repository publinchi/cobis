use cob_credito
go
if object_id ('dbo.sp_cons_soli_cli') is not null
    drop proc sp_cons_soli_cli
go

/********************************************************************/
/*   NOMBRE LOGICO:         sp_cons_soli_cli                        */
/*   NOMBRE FISICO:         sp_cons_soli_cli.sp                     */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          S. Rojas.                               */
/*   FECHA DE ESCRITURA:    01-Oct-2015                             */
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
/*   Este stored procedure permite consultar informacion reimpresion*/
/*   de documentos                                                  */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   01-Oct-2015        S. Rojas.       Emision Inicial             */
/*   28-Dic-2015        N. Trujillo.    Reimpresion Reclamos        */
/*   26-Ene-2023        P. Jarrin.      S762802 - Integracion Reimp */
/*   27-Feb-2023        P. Jarrin.      S779017 - Reporte T.Amortiz */
/********************************************************************/

create proc sp_cons_soli_cli(
       @t_debug          char(1)     = 'N',
       @t_file           varchar(14) = null,
       @i_operacion      char,
       @i_tramite        int         = null,
       @i_login          varchar(50) = null,
       @t_trn            int         = null,
       @i_cliente        int         = null,
       @i_oficial        int         = null,
       @i_tipo_tramite   varchar(3)  = null,
       @i_id_inst_proc   int         = null,
       @i_codigo_alterno varchar(50) = null,
       @i_nemonico       varchar(50) = null,
       @i_claimant       varchar(20) = null
)
as
declare @w_cod_oficial              int,
        @w_sp_name                  varchar(50),
        @w_tramite                  int,
        @w_tipo_tramite             varchar(3),
        @w_consulta                 varchar(2500),
        @w_consulta_condiciones_pt1 varchar(250),
        @w_consulta_condiciones_pt2 varchar(250),
        @w_order_by                 varchar(250),
        @w_nemonico_gestrec         varchar(10),
        @w_tipo_cliente             char(1) 

select @w_sp_name = 'sp_cons_soli_cli'
select @i_claimant = isnull(@i_claimant ,'')
select @w_tipo_cliente = ''

set @w_consulta_condiciones_pt1 = ''
set @w_consulta_condiciones_pt2 = ''
set @w_order_by = ''

select @w_nemonico_gestrec = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'GESTRE'
and    pa_producto = 'CRE'


if @i_operacion = 'S'
begin
   if @t_trn = 22555
   begin
      if @i_nemonico is null and @i_codigo_alterno is not null
      begin
         select @i_nemonico = pr_nemonico
         from   cob_workflow..wf_inst_proceso
                inner join cob_workflow..wf_proceso on io_codigo_proc = pr_codigo_proceso
         where  io_codigo_alterno = @i_codigo_alterno
      end

      if  @w_nemonico_gestrec <> isnull(@i_nemonico, ' ')
      begin
         if (@i_cliente is null and @i_id_inst_proc  is null and @i_codigo_alterno is null and @i_tipo_tramite is null)
         begin
            -- No existe datos
            exec cobis..sp_cerror
                 @t_debug    = @t_debug,
                 @t_file     = @t_file,
                 @t_from     = @w_sp_name,
                 @i_num      = 101001
         end

         if (@i_id_inst_proc  is not null or @i_codigo_alterno is not null or @i_tipo_tramite is not null)
         begin		 
			 select distinct @w_tipo_cliente = io_tipo_cliente
			   from cob_workflow..wf_inst_proceso
			  where (io_codigo_proc     =  convert(int,@i_tipo_tramite) or @i_tipo_tramite   is null)
				and (io_id_inst_proc    =  @i_id_inst_proc              or @i_id_inst_proc   is null)
				and (io_codigo_alterno  =  @i_codigo_alterno            or @i_codigo_alterno is null)
		 end		
  
         if ((@w_tipo_cliente = 'P' or @w_tipo_cliente = '' ) and (@i_claimant = '' or @i_claimant <> 'GS'))
		 begin
             select  'Codigo Solicitud' = io_id_inst_proc,
                     'Codigo Alterno'   = io_codigo_alterno,
                     'Codigo Credito'   = tr_tramite,
                     'Tipo Flujo'       = tr_tipo,
                     'Deudor Principal' = isnull(de_cliente,tr_cliente),
                     'Nombre Deudor'    = en_nomlar,
                     'Monto Propuesto'  = tr_monto,
                     'Moneda Propuesta' = tr_moneda,
                     'Operacion'        = op.op_banco,
                     'Codigo Ciudad'    = tr_ciudad,
                     'Codigo Cliente'   = op.op_cliente,
                     'Cuenta'           = op.op_cuenta,
                     'Nro Operacion'    = op.op_operacion
             from    cob_credito..cr_tramite
                     left    join cobis..cl_ente                on tr_cliente  =  en_ente
                     left    join cob_credito..cr_deudores      on (tr_tramite =  de_tramite and en_ente = de_cliente)
                     inner   join cob_workflow..wf_inst_proceso ip on io_campo_3  =  tr_tramite
                     inner   join cob_cartera..ca_operacion  op   on op.op_tramite = ip.io_campo_3
             where   io_estado          !=  'CAN'
             and     (de_rol             =  'D'                          or de_rol            is null)
             and     (io_codigo_proc     =  convert(int,@i_tipo_tramite) or @i_tipo_tramite   is null)
             and     (de_cliente         =  @i_cliente                   or @i_cliente        is null)
             and     (io_id_inst_proc    =  @i_id_inst_proc              or @i_id_inst_proc   is null)
             and     (io_codigo_alterno  =  @i_codigo_alterno            or @i_codigo_alterno is null)	
           order by tr_tipo, tr_tramite			 
		 end
		 
         if ((@w_tipo_cliente = 'S' or @w_tipo_cliente = '' ) and (@i_claimant = '' or @i_claimant = 'GS'))
		 begin
             select  'Codigo Solicitud' = io_id_inst_proc,
                     'Codigo Alterno'   = io_codigo_alterno,
                     'Codigo Credito'   = tr_tramite,
                     'Tipo Flujo'       = tr_tipo,
                     'Deudor Principal' = op.op_cliente,
                     'Nombre Deudor'    = gr_nombre,
                     'Monto Propuesto'  = tr_monto,
                     'Moneda Propuesta' = tr_moneda,
                     'Operacion'        = op.op_banco,
                     'Codigo Ciudad'    = tr_ciudad,
                     'Codigo Cliente'   = op.op_cliente,
                     'Cuenta'           = op.op_cuenta,
                     'Nro Operacion'    = op.op_operacion
             from    cob_credito..cr_tramite
                     left    join cobis..cl_grupo                  on tr_grupo  =  gr_grupo
                     inner   join cob_workflow..wf_inst_proceso ip on io_campo_3  =  tr_tramite
                     inner   join cob_cartera..ca_operacion  op    on op.op_tramite = ip.io_campo_3
             where   io_estado          !=  'CAN'
             and     (io_codigo_proc     =  convert(int,@i_tipo_tramite) or @i_tipo_tramite   is null)
             and     (tr_grupo           =  @i_cliente                   or @i_cliente        is null)
             and     (io_id_inst_proc    =  @i_id_inst_proc              or @i_id_inst_proc   is null)
             and     (io_codigo_alterno  =  @i_codigo_alterno            or @i_codigo_alterno is null)
             order by tr_tipo, tr_tramite			 
		 end
      end
      else
      begin -- Gestion de reclamos
         select 'Codigo Solicitud' = ip.io_id_inst_proc,
                'Codigo Alterno'   = ip.io_codigo_alterno,
                'Codigo Credito'   = cr.cr_id,
                'Tipo Flujo'       = 'C',
                'Deudor Principal' = case when cr.cr_claimant_id is not null then cr.cr_claimant_id else en.en_ente end,
                'Nombre Deudor'    = case when cr.cr_claimant_id is not null then cc.cc_first_name +' '+cc.cc_last_name+' '+cc.cc_mother_last_name else en.en_nomlar end,
                'Monto Propuesto'  = cr.cr_amount,
                'Moneda Propuesta' = cr.cr_currency,
                'Codigo Ciudad'    = 0,
                'Codigo Cliente'   = en.en_ente,
                'Operacion'        = null,
                'Cuenta'           = null,
                'Nro Operacion'    = null
         from   cob_crm..crm_claim_request cr
                JOIN cob_workflow..wf_inst_proceso ip ON (cr.cr_id             = ip.io_campo_3)
                JOIN cob_workflow..wf_proceso fp      ON (fp.pr_codigo_proceso = ip.io_codigo_proc and fp.pr_nemonico= @w_nemonico_gestrec)
                LEFT JOIN cob_crm..crm_claimant cc    ON (cr.cr_claimant_id    = cc.cc_id)
                LEFT JOIN cobis..cl_ente en           ON (cr.cr_customer_id    = en.en_ente)
         where  (ip.io_id_inst_proc          =    @i_id_inst_proc             or @i_id_inst_proc   is null)
         and    (ip.io_codigo_alterno        like '%' + @i_codigo_alterno+'%' or @i_codigo_alterno is null)
         and    (cr.cr_customer_id           =    @i_cliente                  or @i_cliente        is null)
         and    (cc.cc_identification_number like '%' + @i_claimant+'%'       or @i_claimant       is null)
         order by pr_codigo_proceso
      end
   end
   else
   begin
      --No existe transaccion
      exec cobis..sp_cerror
           @t_debug     = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num     = 151051
      return 1
   end
end --end operacion S


return 0

go

