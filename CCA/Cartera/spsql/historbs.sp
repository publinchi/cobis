/************************************************************************/
/*   Archivo:              historbs.sp                                  */
/*   Stored procedure:     sp_historico_bs                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA"                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Guarda historicos para plano banco segundo piso                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historico_bs')
   drop proc sp_historico_bs
go

create proc sp_historico_bs
       @i_fecha_proceso  datetime
      
as
declare 
   @w_error             int,
   @w_return            int,
   @w_sp_name           descripcion,
   @w_tipo_op           char(1),
   @w_moneda            tinyint,
@w_contador  int



-- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name   = 'sp_historico_bs'



-- INICIAR RESPALDO DE INFORMACION


   insert ca_plano_banco_2piso_his
   select 
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
   case bs_sucursal
        when '040' then substring(bs_oper_llave_redes,5,5)
        when '011' then substring(bs_oper_llave_redes,5,5)
    else 
        substring(bs_oper_llave_redes,7,5)
    end
   from ca_plano_banco_segundo_piso



return 0

go
 





