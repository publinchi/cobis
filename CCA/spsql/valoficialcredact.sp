/************************************************************************/
/*      Archivo:                valoficialcredact.sp                    */
/*      Stored procedure:       sp_validar_oficial_creditos_act         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Agosto-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Validar si el oficial tiene prestamos a cargo para hacer cambio */
/*      de oficina                                                      */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_validar_oficial_creditos_act')
    drop proc sp_validar_oficial_creditos_act
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_validar_oficial_creditos_act
(  
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @t_trn              int          = 0,
   @i_oficial          int,
   @o_retorno          tinyint      out,
   @o_mensaje          varchar(100) out

)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_fec_proceso           datetime,
   @w_error                 int,
   @w_nom_oficial           varchar(30),
   @w_est_vigente         tinyint,
   @w_est_vencido           tinyint,
   @w_est_castigado         tinyint,
   @w_est_diferido           tinyint
   
   
if @t_trn <> 77528
begin        
   select @w_error = 151023
   goto ERROR
end


--Obtener estados no permitidos para cambio de oficial
exec @w_error = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_castigado = @w_est_castigado out,
@o_est_diferido  = @w_est_diferido  out


select @w_nom_oficial = isnull(fu_nombre , '')
from cobis..cl_funcionario, cobis..cc_oficial
where oc_oficial = @i_oficial
and fu_funcionario = oc_funcionario

if isnull(@w_nom_oficial , '') = ''
begin        
   select @w_error = 151091
   goto ERROR
end


if exists (select 1 from ca_operacion 
            where op_oficial = @i_oficial
            and op_estado in (@w_est_vigente, @w_est_vencido, @w_est_castigado, @w_est_diferido))
begin
   select @o_retorno = 1,
          @o_mensaje = 'Oficial [' + trim(@w_nom_oficial) + '], registra operaciones vigentes a su cargo'   
end
else
    select @o_retorno = 0,
           @o_mensaje = ''      

return  0
  
 
ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null, 
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
	 @i_sev   = 0
    
return @w_error
  
go