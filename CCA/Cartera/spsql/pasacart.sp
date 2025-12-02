/************************************************************************/
/*  NOMBRE LOGICO:        pasacart.sp                                   */
/*  NOMBRE FISICO:        sp_pasa_cartera                               */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Fabian de la Torre                            */
/*  FECHA DE ESCRITURA:   07-19-1996 / Ene 98                           */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Pasar a cartera el tramite de credito                           */
/************************************************************************/
/*                            CAMBIOS                                   */
/*   FECHA        AUTOR                    RAZON                        */
/*   --          --                  Version inicial                    */
/*   18/Jun/21   Kevin Rodríguez     Se limita al SP para que genere num*/
/*                                   largo de operacion y cambie num op */  
/*                                   y estado a No vigente              */
/*   16/Dic/21   Johan Hernández     Se realiza proceso con afectación  */
/*                                   a bancos                           */
/*   14/Jun/22   Dilan Morales      Se divide actulizacion de estado y  */
/*                                  numero de banco haciendo uso de     */
/*                                  @i_operacion = B o E.Ademas se      */
/*                                  se comenta codigo desde la linea 228*/
/*   07/Jun/23   Kevin Rodríguez    S809862 Tipo Documento. tributario  */
/*   26/Sep/23   Kevin Rodríguez    S910674-R216163 Ajuste asignación   */
/*                                  Tipo Doc. tributario                */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasa_cartera')
    drop proc sp_pasa_cartera
go

---NR.499 Normalizacion Cartera

create proc sp_pasa_cartera (
@s_ofi                  smallint,
@s_user                 login,
@s_date                 datetime,
@s_term                 descripcion,
@s_ssn                  int,
@i_tramite              int,
@i_operacion            char(1)  =null,
-- @i_forma_desembolso           catalogo  -- KDR 17/06/21 Se comenta parametro
@o_num_banco            varchar(24) = null OUT -- KDR 17/06/21 Variable de salida para nuevo numero de banco
)
as declare
@w_sp_name              varchar(30),
@w_return               int,
@w_operacion            int,
@w_banco                cuenta,
@w_monto                money, 
@w_moneda               tinyint, 
@w_fecha_ini            datetime,
@w_fecha_fin            datetime,
@w_fecha_liq            datetime,
@w_tipo                 char(1) ,
@w_oficina              smallint,
@w_siguiente            int,
@w_est_novigente        smallint,
@w_est_vigente          smallint,
@w_est_credito          smallint,
@w_estado               smallint,
@w_dias                 int,
@w_num_oficial          smallint,
@w_filial               tinyint,
@w_cliente              int, 
@w_direccion            int,
@w_operacionca          int,
@w_reestructuracion     char(1),     -- RRB: 02-21-2002 Circular 50
@w_num_reest            int,      -- RRB: 02-21-2002 Circular 50
@w_op_direccion         tinyint,
@w_rowcount             int,
@w_lin_credito          cuenta,
@w_tramite_cupo         int,
@w_fecha_aprob          datetime,
@w_valor_seguros        money,
@w_monto_cre            money,
@w_tipo_tramite         char(1),
@w_periodo_cap          int,
@w_dist_gracia          char(1),
@w_gracia_cap           int,
@w_secuencial           int,
@w_tipo_amortizacion    catalogo,
@w_beneficiario         varchar(255),
@w_categoria            varchar(10), -- obtiene la categoria de la forma de pago
@w_forma_desem          varchar(10), -- forma de pago
@w_cod_banco_ach        bigint     , -- Codigo banco
@w_cuenta               varchar(30), -- Cuenta asociada al banco 
@w_monto_ds             money      , -- Valor a desembolsar
@w_secuencial_dem       int        , -- Secuencial de desembolso
@w_cont                 int        , -- contador 
@w_desembolso           int        , -- número de desembolso
@w_fecha_proceso        datetime   , -- fecha proceso
@w_error                int        , 
@w_ssn                  int        ,
@w_causal               varchar(14), -- KDR Causal para Bancos según Forma de Pago.
@w_grupal               char(1),         
@w_op_ref_grupal        varchar(24),
@w_tipo_doc_fiscal      varchar(3)

-- OBTENER ESTADOS DE CARTERA   -- KDR 17/06/21
exec @w_return = sp_estados_cca 
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out

if @w_return <> 0 return @w_return


---  VARIABLES DE TRABAJO  
select  
@w_sp_name        = 'sp_pasa_cartera'
  
--CREACION DE TABLA PARA VALIDACIÓN    
create table #ca_desembolso_tmp
(
dmt_cod_banco_recep     bigint         null,  
dmt_cta_recep           varchar(30)    null,  
dmt_beneficiario        varchar(255)   null,        
dmt_monto_mn            money          null,
dmt_secuencial          int            null,
dmt_desembolso          int            null,
dmt_operacion           int            null,
dmt_producto            varchar(10)    null
)

select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7  -- 7 pertenece a Cartera

select 
@w_operacionca = op_operacion,
@w_fecha_liq   = op_fecha_liq,
@w_monto       = op_monto,
@w_moneda      = op_moneda,
@w_fecha_ini   = op_fecha_ini,
@w_fecha_fin   = op_fecha_fin,
@w_oficina     = op_oficina,
@w_banco       = op_banco,  
@w_cliente     = op_cliente,
@w_estado      = op_estado,
@w_op_direccion = op_direccion,
@w_lin_credito   = op_lin_credito,
@w_tipo_amortizacion = op_tipo_amortizacion,
@w_beneficiario  = op_nombre,
@w_grupal        = op_grupal,
@w_op_ref_grupal = op_ref_grupal
from  ca_operacion
where op_tramite = @i_tramite


--Borrado de temporales si existan
IF exists(select 1 from ca_operacion_tmp where opt_operacion = @w_operacionca)
begin
    exec @w_return = sp_borrar_tmp
             @s_sesn   = @s_ssn,
             @s_user   = @s_user,
             @s_term   = @s_term,
             @i_banco  = @w_operacionca
             
    if @w_return != 0  goto ERROR
end


---INC54396  SI LA OBLIGACION POR ALGUN MOTIVO SE PASO YA A ESTADO VIGENTE
---          NO SE PUEDE PASAR POR ESTE PROGRAMA POR QUE SE DANA
if @w_estado = @w_est_vigente
begin
   PRINT 'LA OPERACIONYA SE DESEMBOLSO, NO SE PUEDE PASAR A CARTERA'
   select @w_return = 708152
   goto ERROR
end

IF @i_operacion = 'B'
BEGIN

    -- Generación de nuevo número de banco KDR 17/06/21
    exec @w_return = cob_cartera..sp_numero_oper
               @s_date        = @s_date,
               @i_oficina     = @w_oficina,
               @i_operacionca = @w_operacionca,
               @o_operacion   = 0, 
               @o_num_banco   = @w_banco  out

    if @w_return != 0 
       begin
          select @w_return = 710074
          goto   ERROR
       end   

    -- Retorna el numero de banco KDR 17/06/21
    select @o_num_banco = @w_banco 

    update ca_operacion set 
    op_banco  = @w_banco  --- EL NUEVO NUMERO BANCO SE GENERARA EN LA LIQUIDACION
    where op_tramite = @i_tramite

    if @@error <> 0 
    begin
        select @w_return = 710002
        goto ERROR
    end

END 

IF @i_operacion = 'E'
BEGIN

    update ca_operacion set 
    op_estado = @w_est_novigente
    where op_tramite = @i_tramite

    if @@error <> 0 
    begin
        select @w_return = 710002
        goto ERROR
    end

END

-- Actualiza tipo de documento fiscal (Solo a operaciones que no han sido desembolsadas)
if @w_estado in (@w_est_novigente, @w_est_credito)
begin

   if @w_grupal = 'S' and @w_op_ref_grupal is null -- OP Grupal Padre
      select @w_tipo_doc_fiscal = 'FCF'
   else
   begin
   
      exec sp_func_facturacion
      @i_operacion       = 'D', -- Identificar tipo documento tributario
      @i_opcion          = 0,
      @i_tramite         = @i_tramite,
      @o_tipo_doc_fiscal = @w_tipo_doc_fiscal out

   end

   update ca_operacion_datos_adicionales
   set oda_tipo_documento_fiscal = @w_tipo_doc_fiscal
   where oda_operacion = @w_operacionca
  
   if @@error <> 0
   begin
      select @w_return = 710002 -- Error en la actualizacion del registro
	  goto ERROR
   end 
end	  

/* --DMO SE COMENTA ESTE CODIGO PORQUE SE LLEGO A UN ACUERDO CON ALFREDO MONREY PARA PASAR ESTA LOGICA A OTRO SP
insert into #ca_desembolso_tmp
select dm_cod_banco,
       dm_cuenta,
       dm_beneficiario,
       dm_monto_mn,
       dm_secuencial,
       dm_desembolso,
       dm_operacion,
       dm_producto
from ca_desembolso, ca_producto
where dm_operacion = @w_operacionca
and   cp_producto  = dm_producto
and   cp_categoria = 'CHBC'
and   dm_estado    = 'NA'
order by dm_desembolso

select @w_cont = count(*) from #ca_desembolso_tmp

--JH Afectación PAGO a Banco 
while  @w_cont > 0
begin   
    
    select @w_ssn = -1,
           @w_return = 0,
           @w_error = 0
           
    exec @w_ssn = master..rp_ssn
    -- Se obtiene la información de desembolso
    select top 1
        @w_cod_banco_ach     = dmt_cod_banco_recep,
        @w_cuenta            = dmt_cta_recep,
        @w_beneficiario      = dmt_beneficiario,
        @w_monto_ds          = dmt_monto_mn,
        @w_secuencial_dem    = dmt_secuencial,
        @w_desembolso        = dmt_desembolso,
        @w_operacionca       = dmt_operacion,
        @w_forma_desem       = dmt_producto
    from #ca_desembolso_tmp
    
    select @w_causal = c.valor 
    from cobis..cl_tabla t, cobis..cl_catalogo c
    where t.tabla = 'ca_fpago_causalbancos'
    and t.codigo = c.tabla
    and c.estado = 'V'
    and c.codigo = @w_forma_desem
    
    if @@rowcount = 0 or @w_causal is null
    begin
       select @w_return = 725139
       goto ERROR
    end   
    
    exec  @w_error =  cob_bancos..sp_tran_general  
    @i_operacion      ='I',
    @i_banco          = @w_cod_banco_ach,  
    @i_cta_banco      = @w_cuenta, 
    @i_fecha          = @w_fecha_proceso,
    @i_tipo_tran      = 103, 
    @i_causa          = @w_causal,            -- KDR Causal de la forma de pago
    @i_documento      = @w_banco,                 
    @i_concepto       = 'DESEMBOLSO CARTERA',
    @i_beneficiario   = @w_beneficiario,
    @i_valor          = @w_monto_ds,   
    @i_producto       = 7,
    @i_sec_monetario  = @w_desembolso,
    @t_trn            = 171013, 
    @i_ref_modulo2    = @s_ofi,
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_ofi            = @s_ofi,
    @s_ssn            = @w_ssn,
    @s_corr           = 'I',
    @s_date           = @s_date
                   
                    
    if @w_error <> 0
    begin
        select @w_error = 710001
        goto ERROR
    end 
    
    delete #ca_desembolso_tmp 
    where dmt_secuencial = @w_secuencial_dem
    and   dmt_desembolso = @w_desembolso 
    and   dmt_operacion  = @w_operacionca
    
    select @w_cont = @w_cont -1
end

drop table #ca_desembolso_tmp
*/
return 0

ERROR:
    print 'Error: ' + convert(varchar, @w_return)
    drop table #ca_desembolso_tmp
    return @w_return
GO

