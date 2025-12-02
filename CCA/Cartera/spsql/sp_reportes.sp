/************************************************************************/
/*   Archivo:             sp_reportes.sp                                */
/*   Stored procedure:    sp_reportes                                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Adriana Chiluisa                              */
/*   Fecha de escritura:  05/Sep./2017                                  */
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
/*   Consulta para reportes                                             */
/*                         MODIFICACIONES                               */
/*    05/SEP/2017            ACHP               Emision Inicial-Pagare  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reportes')
   drop proc sp_reportes
go

create proc sp_reportes (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_tramite           char(1)     = null,   
   @i_operacion         char(1)     = null,
   @i_banco             cuenta      = null,
   @i_formato_fecha     int         = null,
   @i_opcion            varchar(10) = null,
   @i_modo              int         = null,
   @i_grupo             int         = null,
   @i_moneda            int         = 0
)
as
declare
   @w_sp_name                      varchar(32),
   @w_ruc                          varchar(64),
   @w_sucursal                     varchar(64),
   @w_fecha                        varchar(10),
   @w_num_recibo                   varchar(10),
   @w_num_operacion                varchar(10), 
   @w_deudor_principal             varchar(64),   
   @w_nombre_grupo                 varchar(30),    
   @w_identificacion               varchar(64),   
   @w_fecha_liq                    varchar(10),
   @w_fecha_desemb                 varchar(10),
   @w_telefono                     varchar(10),
   @w_fecha_ven                    varchar(10),
   @w_direccion                    varchar(64),                 
   @w_ciudad                       varchar(10),
   @w_telefono_Pie                 varchar(10),
   @w_autorizado_por               varchar(10),
   @w_recibe_conforme              varchar(10),
   @w_moneda                       int,
   @w_grupo                        int,
   @w_ente_p                       int    

select @w_sp_name       = 'sp_reportes'

print '---INicioAAA:'+@i_opcion+'---OPer:'+@i_operacion+'---Modo:'+convert(varchar,@i_modo)

-- DETALLE
if @i_operacion = 'Q'
begin
  -- Reporte pagare
    if @i_opcion = '1'
    BEGIN    
        DECLARE @w_cod_tab_plazo_ind INT, @w_op_monto money, @w_am_cuota_6 money, @w_am_couta_7 money, 
		        @w_letra_op_monto varchar(100), @w_letra_am_cuota_6 varchar(100), @w_letra_am_cuota_7 varchar(100)
        SELECT  @w_cod_tab_plazo_ind = codigo FROM cobis..cl_tabla WHERE tabla = 'cr_dividendo_report'        

        SELECT
        @w_op_monto = op_monto,        --amount
        @w_am_cuota_6 = (select sum(am_cuota) from cob_cartera..ca_amortizacion  
                         where  am_operacion = OP.op_operacion and am_dividendo=1), --paymentDescription      
        @w_am_couta_7 = (select sum(am_cuota) from cob_cartera..ca_amortizacion  
                         where  am_operacion=OP.op_operacion 
                         and    am_dividendo = (select max(am_dividendo) from cob_cartera..ca_amortizacion  where am_operacion=OP.op_operacion))           --amountFinal
        FROM cob_cartera..ca_operacion OP, cobis..cl_ente WHERE 
        op_banco = @i_banco
		AND en_ente  = op_cliente

        exec cob_credito..sp_conv_numero_letras
             @t_trn 	= 9490,
             @i_opcion  = 4,
             @i_dinero  = @w_op_monto,
             @i_moneda  = @i_moneda,
             @o_letras  = @w_letra_op_monto out /* valor en letras */

        exec cob_credito..sp_conv_numero_letras
             @t_trn 	= 9490,
             @i_opcion  = 4,
             @i_dinero  = @w_am_cuota_6,
             @i_moneda  = @i_moneda,
             @o_letras  = @w_letra_am_cuota_6 out /* valor en letras */                

        exec cob_credito..sp_conv_numero_letras
             @t_trn 	= 9490,
             @i_opcion  = 4,
             @i_dinero  = @w_am_couta_7,
             @i_moneda  = @i_moneda,
             @o_letras  = @w_letra_am_cuota_7 out /* valor en letras */   
			 
        SELECT
        'CAMPO01' = (select UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,''))),			
        'CAMPO02' = op_monto,        --amount
        'CAMPO03' = (SELECT CONVERT(VARCHAR,op_fecha_liq,103)), -- fieldOther 
        'CAMPO04' = convert(varchar(30),op_plazo),    --term
        'CAMPO05' = (SELECT valor FROM cobis..cl_catalogo WHERE tabla = @w_cod_tab_plazo_ind AND codigo =  OP.op_tdividendo),--periodicity
        'CAMPO06' = (select sum(am_cuota) from cob_cartera..ca_amortizacion  
                     where  am_operacion = OP.op_operacion and am_dividendo=1), --paymentDescription      
        'CAMPO07' = (select sum(am_cuota) from cob_cartera..ca_amortizacion  
                     where  am_operacion=OP.op_operacion 
                     and    am_dividendo = (select max(am_dividendo) from cob_cartera..ca_amortizacion  where am_operacion=OP.op_operacion)),            --amountFinal
        'CAMPO08' = (select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto='INT' and ro_operacion = op_operacion),--rate
        'CAMPO09' = (SELECT CONVERT(VARCHAR(30),tr_fecha_apr,@i_formato_fecha) FROM cob_credito..cr_tramite WHERE tr_tramite = OP.op_tramite),--tr_fecha_apr,   --dateApproval
        'CAMPO10' = op_banco,       --bank
        'CAMPO11' = (SELECT CONVERT(VARCHAR(30),op_fecha_liq,@i_formato_fecha)),
		'AVAL'    = (SELECT UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,'')) FROM cobis..cl_ente, cob_credito..cr_tramite 
		             WHERE  tr_tramite = OP.op_tramite and en_ente = tr_alianza),
		'OPERACION' = op_toperacion,
		'ROL'       = (SELECT cg_rol FROM cob_credito..cr_tramite_grupal TG,cobis..cl_cliente_grupo CG
		               WHERE tg_prestamo = op_banco  
					   AND TG.tg_grupo = CG.cg_grupo AND tg_cliente = CG.cg_ente),
		'CAMPO_2_MONTO' = '('+@w_letra_op_monto + ' M.N.)',		
		'CAMPO_6_CUOTA' = '('+@w_letra_am_cuota_6 + ' M.N.)',
		'CAMPO_7_COUTA' = '('+@w_letra_am_cuota_7 + ' M.N.)'
        FROM cob_cartera..ca_operacion OP, cobis..cl_ente WHERE 
        op_banco = @i_banco
		AND en_ente  = op_cliente

  end  
end -- D

return 0

go
