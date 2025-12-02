/************************************************************************/
/*  Archivo:                var_garantiza_10_org.sp                     */
/*  Stored procedure:       sp_var_garantiza_10_org                     */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_var_garantiza_10_org' and type = 'P')
   drop proc sp_var_garantiza_10_org
go

CREATE PROC sp_var_garantiza_10_org
(@s_ssn           	int         = null,
 @t_debug       	char(1)     = 'N',
 @t_file        	varchar(14) = null,
 @t_from        	varchar(30) = null,
 @t_show_version    bit     = 0, -- Mostrar la version del programa
 --variables
 @i_id_inst_proc    int,    --codigo de instancia del proceso
 @i_id_inst_act     int,    
 @i_id_asig_act     int,
 @i_id_empresa      int, 
 @i_id_variable     smallint )
AS
DECLARE @w_sector		varchar(10),
             @w_sp_name      	varchar(32),
             @w_tramite      	int,
	         @w_cliente   		int,
             @w_return       	int,
             ---var variables        
             @w_valor_ant      	varchar(255),
             @w_valor_nuevo    	varchar(255),
             @w_param_porc_ahorros   varchar(10),
             @w_grupo                int,
             @w_saldo_cuenta      money,
             @w_monto_total_cre  money
             

SELECT @w_sp_name='sp_var_garantiza_10_org'
  
if @t_show_version = 1
begin
    print 'Stored procedure sp_var_garantiza_10_org, Version 4.0.0.0'
    return 0
end


SELECT @w_tramite = convert(int,io_campo_3),
@w_grupo = io_campo_1
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

select @w_tramite = isnull(@w_tramite,0)

if @w_tramite = 0 return 0

select @w_param_porc_ahorros = pa_float
from cobis..cl_parametro
where pa_producto = 'CRE'
  and pa_nemonico = 'PAHO'

-- obtengo el monto de los ahorros de cada integrante
select @w_saldo_cuenta       = 0
select @w_saldo_cuenta       = isnull(ah_disponible,0),
         @w_monto_total_cre  = isnull(sum(isnull(tg_monto,0)),0)
from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion, cob_ahorros..ah_cuenta
where tg_tramite = op_tramite
  and op_cuenta  = ah_cta_banco
  and op_tramite = @w_tramite
  and ah_estado not in ('C','N','X')
  group by isnull(ah_disponible,0)

if ((@w_saldo_cuenta) >= (@w_monto_total_cre * @w_param_porc_ahorros /100))
   select @w_valor_nuevo  = 'S'
else
   select @w_valor_nuevo  = 'N'

--insercion en estrucuturas de variables
if @i_id_asig_act is null
  select @i_id_asig_act = 0


-- valor anterior de variable tipo en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  --ya existe
begin
  --print '@i_id_inst_proc %1! @i_id_asig_act %2! @w_valor_ant %3!',@i_id_inst_proc, @i_id_asig_act, @w_valor_ant
  update cob_workflow..wf_variable_actual
     set va_valor_actual = @w_valor_nuevo 
   where va_id_inst_proc = @i_id_inst_proc
     and va_codigo_var   = @i_id_variable    
end
else
begin
  insert into cob_workflow..wf_variable_actual
         (va_id_inst_proc, va_codigo_var, va_valor_actual)
  values (@i_id_inst_proc, @i_id_variable, @w_valor_nuevo )

end
--print '@i_id_inst_proc %1! @i_id_asig_act %2! @w_valor_ant %3!',@i_id_inst_proc, @i_id_asig_act, @w_valor_ant
if not exists(select 1 from cob_workflow..wf_mod_variable
              where mv_id_inst_proc = @i_id_inst_proc AND
                    mv_codigo_var= @i_id_variable AND
                    mv_id_asig_act = @i_id_asig_act)
BEGIN
    insert into cob_workflow..wf_mod_variable
           (mv_id_inst_proc, mv_codigo_var, mv_id_asig_act,

            mv_valor_anterior, mv_valor_nuevo, mv_fecha_mod)
    values (@i_id_inst_proc, @i_id_variable, @i_id_asig_act,
            @w_valor_ant, @w_valor_nuevo , getdate())
			
	if @@error > 0
	begin
            --registro ya existe
			
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file = @t_file, 
          @t_from = @t_from,
          @i_num = 2101002
    return 1
	end 

END

return 0                       

GO
