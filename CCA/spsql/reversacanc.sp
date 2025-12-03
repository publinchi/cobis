/************************************************************************/
/*   Archivo:                 reversacanc.sp                            */
/*   Stored procedure:        sp_reversa_cancela_grp_int_srv            */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Julio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Reversa de la Precancelacion Grupal o Interciclo                   */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   18/Jul/2019   Edison Cajas.     Emision Inicial                    */
/*   16/Ene/2020   Armando Miramon   Se corrige transaccion de pago     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversa_cancela_grp_int_srv')
    drop proc sp_reversa_cancela_grp_int_srv
go

create proc sp_reversa_cancela_grp_int_srv
(
    @s_user          login        = null,
    @s_term          varchar(30)  = null,
    @s_srv           varchar(30)  = null, 
    @s_date          datetime     = null,
    @s_sesn          int          = null,
    @s_ssn           int          = null,
    @s_ofi           smallint     = null,
    @s_rol           smallint     = null,   
    @t_trn           int,
    @i_banco         cuenta,      
    @o_resultado     int          OUT,         
    @o_mensaje       varchar(200) OUT 
)
as

declare 
     @w_sp_name             descripcion   ,@w_error              int         ,@w_return            int
	 ,@w_tipo_grupal        char(1)       ,@w_secuencial_rev     int         ,@w_est_vigente       tinyint
     ,@w_est_vencido        tinyint       ,@w_est_cancelado      tinyint     ,@w_est_novigente     tinyint

/* CREAR TABLA DE OPERACIONES INTERCICLOS */
create table #TMP_operaciones (
       operacion     int,
       banco         cuenta,
       fecha_proceso datetime,
       fecha_liq     DATETIME,
       estado        int)


select @w_sp_name = 'sp_reversa_cancela_grp_int_srv'

if @t_trn <> 77514
begin
    select @w_error = 151051
	select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error	
    goto ERROR
end

/* ESTADOS DE CARTERA */
exec @w_error         = sp_estados_cca
     @o_est_vigente   = @w_est_vigente   out,
     @o_est_vencido   = @w_est_vencido   out,
     @o_est_cancelado = @w_est_cancelado out,
     @o_est_novigente = @w_est_novigente out

if @w_error <> 0 return 708201
 

/*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/
EXEC @w_error  = sp_tipo_operacion
     @i_banco  = @i_banco,
     @o_tipo   = @w_tipo_grupal out

IF @w_error <> 0
BEGIN
   select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error
   goto ERROR
END

/* DETERMINAR LA OPERACION GRUPAL O LA OPERACION INTERCICLO*/
insert into #TMP_operaciones
select op_operacion, op_banco, op_fecha_ult_proceso, op_fecha_liq, op_estado
from   ca_operacion
where  op_banco = @i_banco


/* DETERMINAR LAS OPERACIONES INTERCICLOS */
insert into #TMP_operaciones
select op_operacion, op_banco, op_fecha_ult_proceso, op_fecha_liq, op_estado
from   ca_operacion
where  op_operacion in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @i_banco and dc_tciclo = 'I')   

/* VALIDAR QUE TODAS LAS OPERACIONES ESTEN CANCELADAS ANTES DE REALIZAR LA REVERSA DE LA CANCELACION*/
IF EXISTS (SELECT 1 FROM #TMP_operaciones WHERE estado <> @w_est_cancelado)
begin
   select @w_error = 725056
   select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error
   goto ERROR
end

/* APLICAR PROCESO DE REVERSA GRUPALES */
if @w_tipo_grupal = 'G'
BEGIN 

	select @w_secuencial_rev = max(ab_secuencial_ing) 
		from ca_abono, ca_operacion
	where ab_operacion = op_operacion
		and op_banco = @i_banco
		and ab_estado    = 'A'

   EXEC @w_error            = sp_reversa_pago_grupal
        @s_user             = @s_user,
        @s_term             = @s_term,
        @s_srv              = @s_srv,
        @s_date             = @s_date,
        @s_sesn             = @s_sesn,
        @s_ssn              = @s_ssn,
        @s_ofi              = @s_ofi,
        @s_rol              = @s_rol,
        @i_banco            = @i_banco,
        @i_secuencial_pago  = NULL,
        @i_secuencial_ing   = @w_secuencial_rev

   IF @w_error <> 0
   BEGIN
      select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error
      goto ERROR
   END

END 

/* APLICAR PROCESO DE REVERSA INTERCICLO */
if @w_tipo_grupal = 'I'
BEGIN

	select @w_secuencial_rev = max(ab_secuencial_pag) 
		from ca_abono, ca_operacion
	where ab_operacion = op_operacion
		and op_banco = @i_banco
		and ab_estado    = 'A'

   exec @w_error          = sp_fecha_valor
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_srv            = @s_srv,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @t_trn            = 7049,
        @i_operacion      = 'R',
        @i_banco          = @i_banco,
        @i_secuencial     = @w_secuencial_rev,
        @i_control_pinter = 'S',
        @i_observacion    = 'REVERSA PRECANCELACION INTERCICLO'

   IF @w_error <> 0
   BEGIN
      select @o_mensaje = mensaje, @o_resultado = @w_error from cobis..cl_errores where numero = @w_error
      goto ERROR
   END
END 

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null, 
        @t_from   = @w_sp_name,
        @i_num    = @w_error
	  
return 1
go
