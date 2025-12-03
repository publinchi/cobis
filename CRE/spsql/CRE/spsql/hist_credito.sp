/************************************************************************/
/*  Archivo:                hist_credito.sp                             */
/*  Stored procedure:       sp_hist_credito                             */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  Este stored procedure permite consultar el historial crediticio     */
/*  de Clientes.                                                        */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_hist_credito')
    drop proc sp_hist_credito
go

create proc sp_hist_credito(
   @s_ssn           int          = null,
   @s_user          login        = null,
   @s_sesn          int          = null,
   @s_term          descripcion  = null,
   @s_date          datetime     = null,
   @s_srv           varchar(30)  = null,
   @s_lsrv          varchar(30)  = null,
   @s_rol           smallint     = null,
   @s_ofi           smallint     = null,
   @s_org_err       char(1)      = null,
   @s_error         int          = null,
   @s_sev           tinyint      = null,
   @s_msg           descripcion  = null,
   @s_org           char(1)      = null,
   @t_rty           char(1)      = null,
   @t_trn           smallint     = null,
   @t_debug         char(1)      = 'N',
   @t_file          varchar(14)  = null,
   @t_from          varchar(30)  = null,
   @i_tramite       int          = null,
   @i_operacion     char(1)      = null,
   @i_observaciones varchar(255) = null
)
as

declare
   @w_return         int,          
   @w_today          datetime,     
   @w_sp_name        descripcion,
   @w_toperacion     catalogo,
   @w_producto       catalogo,
   @w_monto          money,
   @w_moneda         tinyint,
   @w_periodo        catalogo,
   @w_num_periodos   smallint,
   @w_fecha_apr      datetime,
   @w_usuario_apr    login,
   @w_tipo           char(1),
   @w_comite         catalogo, 
   @w_acta           cuenta,
   @w_linea_credito  int,
   @w_admisible      money,
   @w_noadmis        money,
   @w_grupo          int,
   @w_cliente        int,
   @w_num_dias       smallint,
   @w_operacion      int,
   @w_num_ope        char(24),
   @w_tdividendo     catalogo,
   @w_periodo_int    smallint,
   @w_tasa           float,
   @w_fpago_tasa     char(1),
   @w_estado         char(1),
   @w_historia       int,
   @w_tperiodicidad  int,
   @w_cperiodicidad  int,
   @w_tmodalidad     descripcion,
   @w_comision       float,
   @w_fpago_com      char(1),
   @w_cmodalidad     descripcion,
   @w_bandera        char(1),
   @w_linea          cuenta,
   @w_razon          catalogo,
   @w_proposito      catalogo,
   @w_efecto         catalogo,
   @w_txt_razon      varchar(255),

   @o_siguiente      int,
   @o_historia       int
 
select 
@w_toperacion    = tr_toperacion,
@w_producto      = tr_producto,
@w_monto         = tr_monto,
@w_moneda        = tr_moneda,
@w_periodo       = tr_periodo,
@w_num_periodos  = isnull(tr_num_periodos,0),
@w_fecha_apr     = getdate(),				---LNP Nov 2005. TS campo fecha_hora   
@w_usuario_apr   = tr_usuario_apr,
@w_tipo          = tr_tipo,
@w_comite        = tr_comite,
@w_acta          = tr_acta,
@w_linea_credito = tr_linea_credito,
@w_admisible     = tr_admisible,
@w_noadmis       = tr_noadmis,
@w_grupo         = tr_grupo,
@w_cliente       = tr_cliente,
@w_num_dias      = tr_num_dias,
@w_estado        = tr_estado,
@w_num_ope       = tr_numero_op_banco,
@w_razon         = tr_razon,
@w_efecto        = tr_efecto,
@w_proposito     = tr_proposito, 
@w_txt_razon     = tr_txt_razon
from cr_tramite
where tr_tramite = @i_tramite

if @i_operacion = 'R'
begin
   select 
   @w_estado    = 'R'
end

if @w_linea_credito is not null
   select @w_linea = li_num_banco
   from   cr_linea
   where  li_numero = @w_linea_credito

if @w_producto = 'CCA'
begin
   select  
   @w_operacion = op_operacion,
   @w_tdividendo = op_tdividendo,        
   @w_periodo_int = op_periodo_int,
   @w_num_periodos = op_plazo,
   @w_periodo      = op_tplazo
   from    cob_cartera..ca_operacion
   where   op_tramite = @i_tramite

   /* TASA DE INTERES Y LA MODALIDAD */
   select  @w_tasa = ro_porcentaje,
	   @w_fpago_tasa = ro_fpago             
   from    cob_cartera..ca_rubro_op
   where   ro_operacion = @w_operacion
   and     ro_fpago in ('A','P')
   and     ro_tipo_rubro = 'I'  

   /* COMISION Y MODALIDAD  */
   select  @w_comision = ro_porcentaje,
	   @w_fpago_com = ro_fpago
   from    cob_cartera..ca_rubro_op
   where   ro_operacion = @w_operacion
   and     ro_fpago = 'M'                     
   and     ro_tipo_rubro not in ('C','M')     

   if @w_fpago_tasa = 'L'
      select @w_tmodalidad = 'EN EL DESEMBOLSO'
   else if @w_fpago_tasa = 'P'
      select @w_tmodalidad = 'AL VENCIMIENTO'
   else if @w_fpago_tasa = 'A'
      select @w_tmodalidad = 'ANTICIPADO'

   if @w_fpago_com = 'L'
      select @w_cmodalidad = 'EN EL DESEMBOLSO'
   else if @w_fpago_com = 'P'
      select @w_cmodalidad = 'AL VENCIMIENTO'
   else if @w_fpago_com = 'A'
      select @w_cmodalidad = 'ANTICIPADO'
end 

if @w_tipo = 'C'
   select @w_num_periodos = @w_num_dias,
   @w_toperacion = 'CUPO',
   @w_producto = 'CRE'

if @w_tipo = 'G'
   select @w_toperacion = 'GARANTIA',
   @w_producto = 'GAR'


if exists(select 1 from cr_hist_credito
          where  ho_num_tra = @i_tramite)
          select @w_bandera = 'U'
else
   select @w_bandera = 'I'

begin tran


if @w_bandera = 'I'
begin

   select @w_historia = @i_tramite

   delete  cr_hist_credito
   where   ho_historia = @w_historia 

   insert into cr_hist_credito
	   (ho_ente,           ho_historia,     ho_toperacion,
    ho_producto,       ho_monto,        ho_moneda,
    ho_periodo,        ho_num_periodos, ho_num_tra,
    ho_num_ope,        ho_estado,       ho_fecha_aprob,
    ho_fecha_liq,      ho_fecha_venc,   ho_observaciones,
    ho_comportamiento, ho_tipo_tram,    ho_admisible,
    ho_noadmis,        ho_grupo,        ho_comite,
    ho_acta,           ho_func_aprob,   ho_tasa,
    ho_tperiodicidad,  ho_tmodalidad,   ho_comision,
    ho_cperiodicidad,  ho_cmodalidad,   ho_linea,
    ho_razon,          ho_proposito,    ho_txt_razon,
    ho_efecto )
   values
   (@w_cliente,        @w_historia,     @w_toperacion,
    @w_producto,       @w_monto,        @w_moneda,
    @w_periodo,        @w_num_periodos, @i_tramite,
    @w_num_ope,        @w_estado,       @w_fecha_apr,
    NULL,
    NULL,@i_observaciones,
    NULL,
    @w_tipo,         @w_admisible, @w_noadmis,
    @w_grupo,        @w_comite,    @w_acta,
    @w_usuario_apr,  @w_tasa,      @w_tperiodicidad,
    @w_tmodalidad,   @w_comision,  @w_cperiodicidad,
    @w_cmodalidad,   @w_linea,
    @w_razon,        @w_proposito, @w_txt_razon,
    @w_efecto )

   if @@error <> 0 
   begin
      /* ERROR EN INSERCION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2103001
      rollback tran
      return 1 
   end

commit tran
end   

/* ACTUALIZACION DE REGISTRO */
if @w_bandera = 'U'
begin
   update cr_hist_credito
   set
   ho_ente = @w_cliente,          -- ENTE
   ho_toperacion = @w_toperacion,
   ho_producto = @w_producto,
   ho_monto = @w_monto,
   ho_moneda = @w_moneda,
   ho_periodo = @w_periodo,
   ho_num_periodos = @w_num_periodos,
   ho_num_ope = @i_operacion,
   ho_estado = @w_estado,
   ho_fecha_aprob = @w_fecha_apr,
   ho_fecha_liq = NULL,            -- FALTA DEFINIR    
   ho_fecha_venc = NULL,           -- FALTA DEFINIR
   ho_observaciones = @i_observaciones,
   ho_comportamiento = NULL,      -- FALTA DEFINIR
   ho_tipo_tram = @w_tipo,
   ho_admisible = @w_admisible,
   ho_noadmis = @w_noadmis,
   ho_grupo = @w_grupo,
   ho_comite = @w_comite,
   ho_acta = @w_acta,
   ho_func_aprob = @w_usuario_apr,
   ho_tasa = @w_tasa,
   ho_tperiodicidad = @w_tperiodicidad,
   ho_tmodalidad = @w_tmodalidad,
   ho_comision = @w_comision,
   ho_cperiodicidad = @w_cperiodicidad,
   ho_cmodalidad = @w_cmodalidad,
   ho_linea = @w_linea
   where ho_num_tra = @i_tramite

   if @@error <> 0 
   begin
      /* ERROR EN ACTUALIZACION DE REGISTRO */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2105001
      return 1 
   end

commit tran
end     

return 0
go
