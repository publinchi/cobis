/******************************************************************/
/*  Archivo:            vinctaho.sp                               */
/*  Stored procedure:   sp_vincula_ctaho                          */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 08-Mar-2018                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Consultar las cuentas de ahorro activas de un cliente      */
/*   - De no existir la cuenta de ahorro, crearla                 */
/*   - Asociar cuenta de ahorro activa a la operaci¢n de CCA      */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  11-Mar-2019        Lorena Regalado  Integracion CCA-WF        */
/*  02-Abr-2019        Adriana Giler    Reactivar Cuenta          */
/*  06-Ene-2020        Jose Escobar     CAR-S304815-TEC (R131842) */
/*  13-Ene-2020        Eric Galicia     Borrar GAT real y nominal */
/*  20-Feb-2020        Luis Ponce       Cambio de longitud CTA AHO*/
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_vincula_ctaho')
   drop proc sp_vincula_ctaho
go

create proc sp_vincula_ctaho
   @s_sesn                 int          = null,
   @s_date                 datetime,
   @t_trn                  int          = null,
   @s_user                 login        = null,
   @s_culture              varchar(10)  = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_org                  char(1)      = null,
   @s_srv                  varchar (30) = null,
   @s_ofi                  smallint     = null,
   @s_lsrv                 varchar (30) = null,
   @s_rol                  int          = null,
   @i_operacion            int


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_mensaje              varchar(64),
   @w_nro_cta              int,
   @w_prod_ban             smallint,
   @w_ah_cta_banco         cuenta, --char(16), --LPO CDIG. Cambió la longitud de la cuenta de ahorros a 19 dígitos
   @w_en_oficial           smallint,
   @w_rowcount             int,
   @w_moneda_op            tinyint,
   @w_fpago                catalogo,
   @w_return               int,
   @w_cliente              int,
   @w_variables             varchar(255),
   @w_return_variable       varchar(255),
   @w_return_results        varchar(255),
   @w_last_condition_parent varchar(10)

select @w_sp_name = 'sp_vincula_ctaho',
       @w_return  = 0


--VALIDAR QUE EXISTA LA OPERACION DE CARTERA
select @w_moneda_op = op_moneda,
       @w_cliente   = op_cliente,
       @w_variables = op_toperacion
from cob_cartera..ca_operacion
where op_operacion   = @i_operacion
and   op_estado      in(0, 99)          --En Proceso de aprobacion o pendiente de liquidación

if @w_moneda_op is null
    select @w_error = 108002

--OBTENER EL PRODUCTO BANCARIO
print 'REGLA PCCAPAHO VALORES:[' + @w_variables + ']'
-- EJECUTA LA REGLA
exec @w_error                 = cob_pac..sp_rules_param_run
     @i_rule_mnemonic         = 'PCCAPAHO',
     @i_var_values            = @w_variables,
     @i_var_separator         = '|',
     @o_return_variable       = @w_return_variable  OUT,
     @o_return_results        = @w_return_results   OUT,
     @o_last_condition_parent = @w_last_condition_parent OUT
if @w_error <> 0
   return @w_error
print 'REGLA PCCAPAHO VALORES:[' + @w_variables + '] - RESPUESTA[' + @w_return_results + ']'

set @w_return_results = ltrim(rtrim(@w_return_results))
set @w_return_results = replace(@w_return_results,'|','')

select @w_prod_ban = pb_pro_bancario
from   cob_remesas..pe_pro_bancario
where  pb_nemonico = @w_return_results

if  @w_prod_ban is null
    select @w_error = 351015

--OBTENER EL NEMONICO DE LA FORMA DE PAGO AUTOMATICA
select @w_fpago = pa_char
from cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DEBCTA'

if @@rowcount = 0
    select @w_error = 141140

if @w_error > 0
    goto ERROR


--CONSULTA DE DATOS DEL CLIENTE
select @w_en_oficial = en_oficial
from cobis..cl_ente
where en_ente = @w_cliente

select @w_rowcount = @@rowcount

if @w_rowcount = 0
begin
    select @w_mensaje =  'No Existe Cliente: ' + Cast(@w_cliente as varchar),
           @w_error = 50021
    goto ERROR
end

--VALIDAR EL OFICIAL ASOCIADO AL CLIENTE
if not exists (select oc_oficial
               from   cobis..cc_oficial
               where  oc_oficial = @w_en_oficial)
begin
  /* No existe oficial */
  select @w_mensaje = 'No existe oficial en arbol de oficiales',
         @w_error = 151091
  goto ERROR
end

Select @w_nro_cta = 0

--VALIDAR EXISTENCIA DE CUENTA DE AHORROS DEL CLIENTE QUE NO ESTEN CERRADAS
Select @w_nro_cta = count(1)
from cob_ahorros..ah_cuenta
where ah_cliente = @w_cliente
and ah_prod_banc = @w_prod_ban
and ah_estado != 'C'
and ah_moneda = @w_moneda_op

BEGIN TRAN
    if @w_nro_cta = 0
    begin
        --EJECUTAR CREACION DE LA CUENTA DE AHORRO
        exec @w_return = cob_ahorros..sp_apertura_automatica_ah
             @s_ssn         = @s_ssn,
             @s_srv         = @s_srv,
             @s_lsrv        = @s_lsrv,
             @s_user        = @s_user,
             @s_sesn        = @s_sesn,
             @s_term        = @s_term,
             @s_date        = @s_date,
             @s_ofi         = @s_ofi,
             @t_trn         = 201,
             @i_ofl         = @w_en_oficial,
             @i_cli         = @w_cliente,
             @i_tipodir     = 'N',                    -- DEFAULT = 'N' para indicar que no imprime estado de cuenta
             @i_mon         = @w_moneda_op,
             @i_agencia     = @s_ofi,
             @i_prodbanc    = @w_prod_ban,
             @i_origen      = '24',                   -- EN EL CATALOGO ATUAL TIENE CODIGO 24 PARA ORIGEN PO DESEMBOLSO CARTERA
             @o_cta         = @w_ah_cta_banco out

        if @w_return != 0
        begin
           select @w_error = @w_return
           goto ERROR
        end
    end
    else
    begin
        set rowcount 1

        -- Si tiene cuenta asociada tomar la activa que tenga último movimiento
        Select @w_ah_cta_banco = ''

        Select @w_ah_cta_banco = ah_cta_banco
        from cob_ahorros..ah_cuenta
        where ah_cliente = @w_cliente
        and ah_prod_banc = @w_prod_ban
        and ah_estado = 'A'
        and ah_moneda = @w_moneda_op
        and ah_fecha_ult_mov = (select max(ah_fecha_ult_mov) from cob_ahorros..ah_cuenta
                                where ah_cliente = @w_cliente
                                and ah_prod_banc = @w_prod_ban
                                and ah_estado = 'A'
                                and ah_moneda = @w_moneda_op)


        if @w_ah_cta_banco = ''  or @w_ah_cta_banco is null
        begin
            --Tomar la cuenta Inactivas con último movimiento
            Select @w_ah_cta_banco = ah_cta_banco
            from cob_ahorros..ah_cuenta
            where ah_cliente = @w_cliente
            and ah_prod_banc = @w_prod_ban
            and ah_estado = 'I'
            and ah_moneda = @w_moneda_op
            and ah_fecha_ult_mov = (select max(ah_fecha_ult_mov) from cob_ahorros..ah_cuenta
                                    where ah_cliente = @w_cliente
                                    and ah_prod_banc = @w_prod_ban
                                    and ah_estado = 'I'
                                    and ah_moneda = @w_moneda_op)

            if @@rowcount != 0
            begin
                --ReActivar Cuenta
                exec @w_return = cob_ahorros..sp_tr_reactivacion_ah
                     @s_ssn    = @s_ssn,
                     @s_srv    = @s_srv,
                     @s_lsrv   = @s_lsrv,
                     @s_user   = @s_user,
                     @s_sesn   = @s_sesn,
                     @s_term   = @s_term,
                     @s_date   = @s_date,
                     @s_ofi    = @s_ofi ,
                     @s_rol    = @s_rol ,
                     @s_org    = 'U',
                     @t_trn    = 203,
                     @i_cta    = @w_ah_cta_banco,
                     @i_mon    = @w_moneda_op

                if @w_return != 0
                begin
                print 'aja'
                   select @w_error = @w_return
                   goto ERROR
                end
            end
        end
    end

    -- Asociar la Cuenta al prestamo
    if @w_ah_cta_banco > ''
    begin
        update cob_cartera..ca_operacion
        set op_cuenta     = @w_ah_cta_banco,
            op_forma_pago = @w_fpago
        where op_operacion = @i_operacion

        if @@error <> 0
        begin
            select @w_mensaje = 'Error al asociar la cuenta a la operacion',
                   @w_error = 705007
            goto ERROR
        end
		
		exec @w_return = cob_ahorros..sp_calcula_gat
           @s_ssn           = @s_ssn,          
           @s_srv           = @s_srv ,         
           @s_lsrv          = @s_lsrv ,        
           @s_user          = @s_user ,        
           @s_term          = @s_term ,        
           @s_date          = @s_date ,        
           @s_ofi           = @s_ofi  ,        
           @s_rol           = @s_rol  ,        
           @t_trn           = 4172  ,        
           @i_operacion     = 'B',    
           @i_cta           = @w_ah_cta_banco

		if @w_return <> 0
        begin
            select @w_mensaje = 'Error al borrar valores de GAT nominal y real.',
                   @w_error = 77539
            goto ERROR
        end
    end

COMMIT TRAN
return 0

ERROR:

   while @@trancount > 0 ROLLBACK TRAN

   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_mensaje

   return @w_error

go


