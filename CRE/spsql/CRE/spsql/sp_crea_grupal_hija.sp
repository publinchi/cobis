/*************************************************************************/
/*   Archivo:              sp_crea_grupal_hija.sp                        */
/*   Stored procedure:     sp_crea_grupal_hija                           */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Carlos Veintemilla							 */
/*   Fecha de escritura:   1/Jul/2021                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las? convenciones? internacionales de? propiedad inte-        */
/*   lectual.? Su uso no? autorizado dara? derecho a? MACOSA para        */
/*   obtener? ordenes de? secuestro o retencion y? para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Reserva secuenciales para los tramites hijos y llame al sp         */
/*    que crear los tramites hijos								         */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                   RAZON                	 */
/*    1/Jul/2021    	  Carlos Veintemilla      Emision Inicial        */
/*                                                                       */
/*************************************************************************/
use cob_credito
go

IF OBJECT_ID ('dbo.sp_crea_grupal_hija') IS NOT NULL
	DROP PROCEDURE dbo.sp_crea_grupal_hija
GO

create proc sp_crea_grupal_hija
(
   @s_sesn                 int          = null,
   @s_date                 datetime     = null,
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
   @i_tramite              int
)
as 
declare
   @w_sp_name              varchar(30),
   @w_return               int,
   @w_fecha_proceso        datetime,
   @w_count_hija           int,
   @w_count                int,
   @w_sec_hijas            varchar(200),
   @w_secuencia            int,         
   @o_error                int,
   @w_mensaje              varchar(64),
   @w_clte_error           int,
   @w_error                int,
   @w_ssn                  int,
   @w_oficina              smallint

select @w_sp_name = 'sp_crea_grupal_hija',
       @w_return  = 0

select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso

select @w_count_hija = count(1)
from   cob_credito..cr_tramite_grupal
where  tg_tramite = @i_tramite
and    tg_participa_ciclo = 'S'
        
select @w_sec_hijas = ''
        
select @w_count = 1
        
while @w_count <= @w_count_hija 
begin
   exec @w_secuencia = ADMIN...rp_ssn
            
   select @w_sec_hijas = @w_sec_hijas + convert(varchar,@w_secuencia)+'|'
            
   select @w_count = @w_count + 1
   
END

Begin Tran
exec @w_return = sp_crear_hijas
                 @s_user      = @s_user,  
                 @s_date      = @s_date,  
                 @s_term      = @s_term, 
                 @s_ofi       = @s_ofi,   
                 @t_trn       = @t_trn,   
                 @s_lsrv      = @s_lsrv,
                 @i_tramite   = @i_tramite,
                 @i_sec_hijas = @w_sec_hijas,
                 @o_clte_err  = @w_clte_error out ,
                 @o_mensaje   = @w_mensaje    out
                 
if @w_return != 0
begin
   Rollback Tran
end   
else
begin            
   Commit Tran
end

return 0

ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error

    return @w_error
GO
