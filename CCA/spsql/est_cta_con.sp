/***********************************************************************/
/*	Archivo:			est_cta_con.sp                                 */
/*	Stored procedure:		sp_estado_cta_consol                       */
/*	Base de Datos:			cob_cartera                                */
/*	Producto:			Cartera	                                       */
/*	Disenado por:			LPO                                        */
/*	Fecha de Documentacion: 	May. 2017                              */
/***********************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/***********************************************************************/  
/*			PROPOSITO				                                   */
/*	Mostrar el estado de cuenta consolidado                            */
/***********************************************************************/
use cob_cartera
go
if exists(select * from sysobjects where name = 'sp_estado_cta_consol')
	drop proc sp_estado_cta_consol
go
create proc sp_estado_cta_consol (
@i_banco		cuenta   = null,
@i_opcion               char(1)  = null,
@s_date                 datetime = null
)
as
declare
 	@w_sp_name	    varchar(32),	
	@w_opcion	    int,
        @w_error            int,
        @w_estado           int,
        @w_formato_fecha    int,
        @w_seguro_desgrav   money,
	@w_grupo            int,
        @w_nombre_grupo     varchar(30),
        @w_filial           varchar(30),
        @w_fecha            varchar(10),
        @w_cuenta           varchar(30),
        @w_total            money,
        @w_dia_reunion          tinyint,
        @w_frecuencia_reunion   smallint,
        @w_hora_reunion         varchar(5),
        @w_lugar_reunion        varchar(64),
        @w_referencia_grupal    varchar(20),
        @w_moneda               tinyint,
        @w_cliente              int,
        @w_nombre               varchar(40),
        @w_banco                varchar(15),
        @w_ced_ruc              varchar(15),
        @w_tramite              int,
        @w_dd_hoy               tinyint,
        @w_mm_hoy               tinyint,
        @w_yy_hoy               smallint,
        @w_direccion            varchar(45),
        @w_reunion              varchar(255),
        @w_est_vigente          tinyint,
        @w_est_novigente        tinyint,
        @w_est_vencido          tinyint,
        @w_est_cancelado        tinyint,
        @w_ruc                  varchar(30),
		@w_dia_reunion_desc     varchar(10),
		@w_fondo                varchar(255),
        @w_ciclos               int,
        @w_oficina              int,
        @w_nombre_oficina       varchar(30),		
        @w_oficial              int,
        @w_nombre_oficial       varchar(35),		
        @w_destino              varchar(2),
        @w_desc_destino         varchar(64),
		@w_asesor               varchar(64),
		@w_monto_prestado       money,		
		@w_tasa_interes         money,
		@w_plazo_descrip        varchar(64),
		@w_fecha_desembolso     datetime,
		@w_abrev_moneda         varchar(10),
		@w_operacion            int

/*  Captura nombre de Stored Procedure  */
select  @w_sp_name = 'sp_estado_cta_consol',
        @w_formato_fecha = 103,
        @w_est_novigente = 0,
        @w_est_vigente   = 1,
        @w_est_vencido   = 2,
        @w_est_cancelado = 3
        --@w_titulo        = 'ESTADO DE CUENTA CONSOLIDADO',
       
if @i_opcion = 'C'
begin
   declare @w_cod_tb_cat_linea smallint
   select  @w_cod_tb_cat_linea = codigo from cobis..cl_tabla where tabla = 'ca_categoria_linea'
   
   select @w_fecha            = convert(varchar(10),@s_date,@w_formato_fecha),
          @w_grupo            = gr_grupo,
		  @w_ciclos           = gr_num_ciclo,
          @w_nombre_grupo     = substring(gr_nombre,1,30),
		  @w_dia_reunion_desc = (select valor
                                 from   cobis..cl_catalogo a, cobis..cl_tabla b
                                 where  a.tabla        = b.codigo
                                 and    b.tabla        = 'ad_dia_semana'
                                 and    a.codigo       = gr_dia_reunion),
		 @w_hora_reunion      = convert(varchar,gr_hora_reunion,108),
		 @w_lugar_reunion     = gr_dir_reunion,
		 @w_oficina           = op_oficina,
		 @w_oficial           = op_oficial,
		 @w_desc_destino      = ( select valor
		                         from cobis..cl_catalogo a, cobis..cl_tabla b
                                 where a.tabla = b.codigo
                                 and b.tabla   = 'cr_objeto'
                                 and a.codigo  = OP.op_destino),
		 @w_monto_prestado    = op_monto,
		 @w_fecha_desembolso  = op_fecha_liq,
		 @w_operacion         = op_operacion,
		 @w_plazo_descrip     = (select convert(varchar(10), p.td_factor * op_plazo) + ' dias'
		                         from  ca_tdividendo p
								 where p.td_tdividendo = OP.op_tplazo
                                 and p.td_tdividendo   = OP.op_tdividendo),
		 @w_abrev_moneda      = (select mo_simbolo from cobis..cl_moneda where mo_moneda = OP.op_moneda),
		 @w_fondo		      = (select valor from cobis..cl_catalogo where tabla = @w_cod_tb_cat_linea and codigo = OP.op_origen_fondos )
   from cobis..cl_grupo, cob_credito..cr_tramite, ca_operacion OP
   where op_banco    = @i_banco
   and tr_grupal     = 'S'
   and op_tramite    = tr_tramite		 
   and op_cliente    = gr_grupo
   
   --Datos Oficinal
   select  @w_nombre_oficina = of_nombre,
           @w_ruc            = fi_ruc,
		   @w_filial         = substring(fi_nombre,1,30)
   from    cobis..cl_oficina, cobis..cl_filial 
   where   fi_filial  = 1 
   and     of_filial  = fi_filial
   and     of_oficina = @w_oficina

   -- Datos oficial
   select @w_asesor      = fu_nombre
   from   cobis..cl_funcionario, cobis..cc_oficial
   where  oc_oficial     = @w_oficial
   and    oc_funcionario = fu_funcionario
   
   -- tasa
   select @w_tasa_interes = ro_porcentaje 
   from   ca_rubro_op
   where  ro_concepto = 'INT'
   and    ro_operacion = @w_operacion
		
   select 'FILIAL'         = @w_filial,
          'RUC'            = @w_ruc,
          'FECHA'          = @w_fecha,
          'GRUPO'          = @w_grupo,
          'NOMBRE_GRUPO'   = @w_nombre_grupo,
		  'DIA_REUNION'    = @w_dia_reunion_desc,
		  'HORA_REUNION'   = @w_hora_reunion,
		  'LUGAR_REUNION'  = @w_lugar_reunion,
		  'FONDO'          = @w_fondo,   --Este campo se deja solo referenciado dado que aun no se cuenta con esta informacion
		  'NUM_CICLO'      = @w_ciclos,
		  'SUCURSAL'       = @w_nombre_oficina,
		  'ASESOR'         = @w_asesor,
		  'DESTINO'        = @w_desc_destino,
		  'MONTO_PRESTADO' = @w_monto_prestado,
		  'TASA_INTERES'   = (@w_tasa_interes / 100),
		  'PLAZO'          = @w_plazo_descrip,
		  'FECHA_DESEMBOLSO' = convert(varchar(10),@w_fecha_desembolso,103),		  
		  'ABREV_MONTO_P'  = @w_abrev_moneda							   

end


if @i_opcion = 'D'
begin
  select 'Fecha'     = (select convert(varchar(10),op_fecha_liq,@w_formato_fecha)
                        from cob_cartera..ca_operacion
                        where TG.tg_operacion = op_operacion),
         'Cliente'   = (select UPPER(isnull(en_nombre,''))+' ' + UPPER(isnull(p_s_nombre,''))+' '+
	                           UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))
						  from cobis..cl_ente where en_ente  = TG.tg_cliente),
         'Otorgado'  = (isnull(op_monto,0)),
         'Saldo Cap.'=  (select sum(am_cuota) - sum(am_pagado) + sum(am_gracia)
                        from ca_amortizacion
                        where TG.tg_operacion = am_operacion
                          and am_concepto     = 'CAP'),
         'Ahorros'   = isnull((select sum(isnull(cp_ahorro,0)) + sum(isnull(cp_extras,0))
                        from cob_cartera..ca_control_pago
                        where TG.tg_operacion = cp_operacion),0),
         'Capital'   = (select sum(am_cuota) - sum(am_pagado) + sum(am_gracia)
                        from ca_amortizacion, ca_dividendo
                        where TG.tg_operacion = am_operacion
                          and am_operacion    = di_operacion
                          and am_dividendo = di_dividendo
                          and am_concepto     = 'CAP'
                          and di_estado       NOT in (@w_est_novigente ,@w_est_cancelado)),
         'INT + Otros'= (select sum(am_cuota) - sum(am_pagado) + sum(am_gracia)
                         from ca_amortizacion, ca_dividendo
                         where TG.tg_operacion = am_operacion
                           and am_operacion    = di_operacion
                          and am_dividendo = di_dividendo
                           and am_concepto     <> 'CAP'
                           and di_estado       not in (@w_est_novigente ,@w_est_cancelado)),
         'TOTAL'      = (select sum(am_cuota) - sum(am_pagado) + sum(am_gracia)
                         from ca_amortizacion, ca_dividendo
                         where TG.tg_operacion = am_operacion
                           and am_operacion    = di_operacion
                          and am_dividendo = di_dividendo
                           and di_estado       not in (@w_est_novigente ,@w_est_cancelado)),
		'ID_CLIENTE'  = TG.tg_cliente,
		'NUM_DOC_CLI' = (select convert(varchar(30), en_ced_ruc) from cobis..cl_ente where en_ente = TG.tg_cliente)
   from cob_credito..cr_tramite_grupal TG, ca_operacion OP
   where tg_referencia_grupal = @i_banco
   and   TG.tg_monto > 0
   and   tg_prestamo = op_banco
 
end

return 0
go
