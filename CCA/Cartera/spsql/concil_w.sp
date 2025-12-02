/************************************************************************/
/*	Archivo:		concil_w.sp				*/
/*	Stored procedure:	sp_conciliacion_dia_w		        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Fecha de escritura:	Feb.2003 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Genera diferencias entre los vencimientos enviados por banco de */
/*      de segundo piso y vencimientos de COBIS                         */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*	07/13/2003    Julio C Quintero    Validaci¢n Comparaci¢n Identi-*/
/*                                        ficaci¢n y LLave Redescuento  */   
/************************************************************************/

use cob_cartera
go

/*if exists (select 1 from sysobjects where name = 'ca_datos_concil')
   drop table ca_datos_concil
go

create table ca_datos_concil
(cd_cod_ext_banco     	cuenta,
 bs_cod_ext_banco_s   	cuenta,
 cd_llave_banco       	cuenta,
 bs_llave_banco_s     	cuenta,
 cd_norma_legal       	cuenta,
 bs_norma_legal_s     	cuenta,
 cd_dias_int          	int,
 bs_dias_int_s        	int,
 cd_saldo             	money,
 bs_saldo_s           	money,
 cd_abono_int         	money,
 bs_abono_int_s       	money,
 cd_abono_capital     	money,
 bs_abono_capital_s   	money,
 cd_modalidad_pago    	char(1),
 bs_modalidad_pago_s  	char(1),
 cd_tasa_nominal      	float,
 bs_tasa_nominal_s    	float,
 cd_nombre		varchar(64),
 bs_nombre_s	   	varchar(35),
 cd_indentificacion   	cuenta,
 bs_indentificacion_s 	cuenta,
 cd_formula_tasa      	varchar(20),
 bs_formula_tasa_s    	varchar(15),
 cd_fecha_ven_cuota   	datetime,
 bs_fecha_ven_cuota_s 	datetime,
 cd_banco	   	cuenta,
 cd_oficina        	smallint,
 cd_fecha_redescuento 	datetime
)
go

*/

if exists (select * from sysobjects where name = 'sp_conciliacion_dia_w')
   drop proc sp_conciliacion_dia_w
go


create proc sp_conciliacion_dia_w
@i_fecha_proceso     	datetime
as

declare 
	@w_error		int,
	@w_return         	int,
	@w_sp_name        	descripcion,
	@w_bs_fecha_pago	varchar(10),
	@w_cd_nombre		varchar(20),
	@w_cd_oficina		int,
	@w_cd_fecha_redescuento	datetime,	
	@w_cd_llave_redescuento	cuenta,	
	@w_bs_oper_llave_redes	cuenta,
	@w_bs_tasa_nom		float,
	@w_cd_tasa_nominal	float,
	@w_bs_modalidad		char(1),
	@w_cd_modalidad_pago	char(1),
	@w_bs_dias_int		int,
	@w_cd_dias_interes	int,
	@w_bs_valor_saldo	money,
	@w_cd_saldo_redescuento	money,
	@w_bs_valor_int		money,
	@w_cd_abono_interes	money,
	@w_cd_abono_capital	money,
	@w_bs_valor_cap	        money,
	@w_cd_formula_tasa	varchar(20),
	@w_bs_formula_tasa	varchar(20),
	@w_cd_norma_legal	cuenta,
	@w_bs_linea_norlegal	descripcion,
	@w_cd_fecha_ven_cuota	datetime,
	@w_bs_fecha_ven_int	varchar(10),
	@w_cd_identificacion	cuenta,
	@w_bs_identificacion	cuenta,
        @w_bs_sucursal          varchar(3),
        @w_llave_segundo_p	cuenta,
        @w_llave_segundo_p_concil cuenta,
        @w_centuria             char(1),
        @w_bs_fecha_redescuento datetime,
        @w_bs_nombre            varchar(35),
        @w_cd_banco		cuenta,
        @w_posicion             tinyint

/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name          = 'sp_conciliacion_dia_w'



truncate table ca_datos_concil


/* tabla temporal para datos de Finagro */
CREATE TABLE #tmp_plano_banco_segundo_piso(
  bs_registro                    varchar(1),
  bs_fecha_pago                  datetime,
  bs_grupo                       varchar(2),
  bs_nit                         varchar(15),
  bs_modalidad                   char   (1),
  bs_fecha_vencimiento           varchar(8),
  bs_sucursal                    varchar(3),
  bs_linea_norlegal              varchar(4),
  bs_oper_llave_redes            cuenta,
  bs_identificacion              cuenta,
  bs_nombre                      varchar(35),
  bs_valor_saldo_antes           money,
  bs_abono_capital               money,
  bs_valor_saldo_despues         money,
  bs_fecha_ini_int               varchar(8),
  bs_fecha_ven_int               varchar(8),
  bs_dias_int                    int,
  bs_formula_tasa                varchar(15),
  bs_tasa_nom                    float,
  bs_valor_int                   money,
  bs_valor_pagar                 money,
  bs_residuo                     varchar(51),
  bs_fecha_redescuento           varchar(8)   null,
  bs_z2                          char(1)      null,
  bs_llave                       cuenta
)



INSERT INTO #tmp_plano_banco_segundo_piso
SELECT
bs_registro,
convert(datetime,substring(bs_fecha_pago,3,2) + '/' + substring(bs_fecha_pago,1,2) + '/' + substring(bs_fecha_pago,5,4),101), 
bs_grupo,
bs_nit,
bs_modalidad,
bs_fecha_vencimiento,
bs_sucursal,
bs_linea_norlegal,
bs_oper_llave_redes,
bs_identificacion,
bs_nombre,
bs_valor_saldo_antes,
bs_abono_capital,
bs_valor_saldo_despues,
bs_fecha_ini_int,
bs_fecha_ven_int,
bs_dias_int,
bs_formula_tasa,
bs_tasa_nom,
bs_valor_int,
bs_valor_pagar,
bs_residuo,
bs_fecha_redescuento,
bs_z2,
(ltrim(rtrim(bs_sucursal))) + (ltrim(rtrim(bs_linea_norlegal))) + (ltrim(rtrim(bs_oper_llave_redes)))

from ca_plano_banco_segundo_piso


/* tabla temporal para datos del banco */
CREATE TABLE #tmp_conciliacion_diaria (
  cd_fecha_proceso               datetime,
  cd_fecha_ven_cuota             datetime,
  cd_banco                       cuenta,
  cd_operacion                   int,
  cd_tramite                     int		null,
  cd_oficina                     int,
  cd_llave_redescuento           cuenta,
  cd_fecha_redescuento           datetime,
  cd_nombre                      varchar(64),
  cd_dias_interes                int,
  cd_tasa_nominal                float,
  cd_formula_tasa                varchar(20),
  cd_saldo_redescuento           money,
  cd_abono_capital               money,
  cd_abono_interes               money,
  cd_modalidad_pago              char(1),
  cd_norma_legal                 cuenta,
  cd_prox_interes                datetime,
  cd_valor_capitalizar           money,
  cd_banco_sdo_piso              catalogo,
  cd_identificacion              cuenta,
  cd_estado                      char(1),
  cd_dividendo                   int,
  cd_fecha_desembolso            datetime,
  cd_z1                          char(1),
  cd_w                           char(1),
  cd_llave                       cuenta
)




INSERT INTO #tmp_conciliacion_diaria
SELECT   cd_fecha_proceso,
  cd_fecha_ven_cuota,
  cd_banco,
  cd_operacion,
  cd_tramite,
  cd_oficina,
  cd_llave_redescuento,
  cd_fecha_redescuento,
  cd_nombre,
  cd_dias_interes,
  cd_tasa_nominal,
  cd_formula_tasa,
  cd_saldo_redescuento,
  cd_abono_capital,
  cd_abono_interes,
  cd_modalidad_pago,
  cd_norma_legal,
  cd_prox_interes,
  cd_valor_capitalizar,
  cd_banco_sdo_piso,
  cd_identificacion,
  cd_estado,
  cd_dividendo,
  cd_fecha_desembolso,
  cd_z1,
  cd_w,
  case 
       when cd_fecha_redescuento <= '10/31/1999' then substring(cd_llave_redescuento, datalength(rtrim(ltrim(cd_llave_redescuento))) - 4 , 5)
       when cd_fecha_redescuento >= '02/12/2004' then substring(cd_llave_redescuento, datalength(rtrim(ltrim(cd_llave_redescuento))) - 7 , 6)
       when cd_fecha_redescuento > '10/31/1999' and cd_fecha_redescuento < '02/12/2004' then substring(cd_llave_redescuento, datalength(rtrim(ltrim(cd_llave_redescuento))) - 6 , 5)
  end
from ca_conciliacion_diaria
where cd_fecha_proceso = @i_fecha_proceso
and   cd_banco_sdo_piso = '224'



/*COMPARACION dATOS QUE GENERAN DIFERENCIA */
--Campos a comparar:
	                        -- Norma Legal				
				-- modalidad
				-- No. dias int
				-- Tasa Nominal
                                -- Saldo de Redescuento  JCQ 07/17/2003
                                -- Abono Capital         JCQ 07/17/2003
                                -- Abono Inter‚s         JCQ 07/17/2003
                                -- Llaver de Redescuento


   insert into ca_datos_concil
   select cd_llave_redescuento,      bs_oper_llave_redes,
          cd_llave,                  bs_llave,
          cd_norma_legal,            bs_linea_norlegal,
          cd_dias_interes,           bs_dias_int,
          cd_saldo_redescuento,      bs_valor_saldo_despues/100,
          cd_abono_interes,          bs_valor_int/100,
          cd_abono_capital,          bs_abono_capital/100,
          cd_modalidad_pago,         bs_modalidad,
          cd_tasa_nominal,           bs_tasa_nom/100,
          cd_nombre,		     bs_nombre,
	  cd_identificacion,   	     bs_identificacion,
	  cd_formula_tasa,	     bs_formula_tasa,
	  cd_fecha_ven_cuota,        bs_fecha_pago,
          cd_banco,		     cd_oficina,
          cd_fecha_redescuento
     from #tmp_plano_banco_segundo_piso,
          #tmp_conciliacion_diaria 
     where  bs_fecha_pago = cd_fecha_proceso
     and    cd_llave_redescuento = bs_llave   ---bs_oper_llave_redes
     and    bs_fecha_pago = @i_fecha_proceso
     and   (cd_norma_legal   <> bs_linea_norlegal or cd_modalidad_pago    <> bs_modalidad  or
            cd_tasa_nominal  <> bs_tasa_nom/100   or cd_saldo_redescuento <> bs_valor_saldo_despues/100 or
            cd_abono_capital <> bs_abono_capital/100  or cd_abono_interes     <> bs_valor_int/100) 

          
     update cob_cartera..ca_conciliacion_diaria
     set cd_w = 'S'
     from ca_datos_concil,ca_conciliacion_diaria
     where cd_llave_redescuento = cd_cod_ext_banco 
     and cd_fecha_proceso       = @i_fecha_proceso


 PRINT 'concil_w.sp FIN  LEER VENCIMIENTOS DE FINAGRO'

return 0

go


