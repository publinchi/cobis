use cob_cartera
go

/************************************************************************/
/*   Archivo:              rtrsolwf.sp                                  */
/*   Stored procedure:     sp_rechazar_tram_sol_wf                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Ene-17-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      ENE-17-2017    Raul Altamirano  Emision Inicial - Version MX    */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_rechazar_tram_sol_wf')
    drop proc sp_rechazar_tram_sol_wf
go

create proc sp_rechazar_tram_sol_wf(
   @s_ssn            int,
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_sesn           int,
   @s_ofi            smallint,
   @s_srv            varchar(30) = null,
   @s_lsrv           varchar(30) = null,
   ---------------------------------------
   @t_trn            int         = null,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(14) = null,
   ---------------------------------------
   @i_tipo           varchar(1) = 'O',
   @i_tramite        int        = null,
   @i_banco          cuenta     = null,
   @i_estado         varchar(1) = null,
   @i_razon          catalogo = null,
   @i_txt_razon      varchar(255) = null,
   @i_en_linea       varchar(1)   = 'S',
   @i_externo        varchar(1)   = 'S',
   @i_desde_web      varchar(1)   = 'S',
   @i_banca          catalogo     = null,
   @i_salida         varchar(1)   = 'N',
   ---------------------------------------
   @o_banco          cuenta = null out,
   @o_operacion      int = null out,
   @o_tramite        int = null out,
   @o_msg            varchar(100) = null out
)as 

declare
   @w_sp_name              varchar(64),
   @w_return               int,
   @w_error                int,   
   @w_fecha_proceso        datetime,
   @w_est_novigente        tinyint,
   @w_est_credito          tinyint,
   @w_operacion            int,   
   @w_banco                cuenta,
   @w_tramite              int,
   @w_op_estado            tinyint,
   @w_estado               char(1),
   @w_numero_op_banco      cuenta,
   @w_razon                catalogo,
   @w_txt_razon            varchar(255),
   @w_commit               char(1)
   

PRINT 'CARGAR VALORES INICIALES'
select @w_sp_name  = 'sp_rechazar_tram_sol_wf',
       @w_commit   = 'N'


PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out


if @i_tramite is not null 
begin
   select @w_operacion      = op_operacion,
          @w_op_estado      = op_estado,
          @w_banco          = op_banco
   from   cob_cartera..ca_operacion
   where  op_tramite = @i_tramite
end
else if @i_banco is not null 
begin
   select @w_operacion      = op_operacion,
          @w_op_estado      = op_estado,
          @w_tramite        = op_tramite
   from   cob_cartera..ca_operacion
   where  op_banco = @i_banco
end


if @i_tramite is not null and @i_banco is not null
begin
   if @i_tramite <> @w_tramite or @i_banco <> @w_banco
   begin
      select @w_error = 2101021
      goto ERROR_PROCESO
   end
end


select 
@w_estado           = tr_estado,
@w_razon            = tr_razon,
@w_txt_razon        = tr_txt_razon
from cob_credito..cr_tramite
where tr_tramite = @i_tramite


if @@rowcount = 0
begin
   select @w_error = 2105002
   goto ERROR_PROCESO
end


--MODIFICAR TRAMITE DEBIDO AL RECHAZO
print 'antes de cob_credito..sp_up_tramite'

if @w_op_estado in (@w_est_novigente, @w_est_credito)
begin
   exec @w_return   =  cob_credito..sp_up_tramite_cca
   @s_date                  =  @s_date,
   @s_lsrv                  =  @s_lsrv,
   @s_ofi                   =  @s_ofi,
   @s_sesn                  =  @s_sesn,
   @s_srv                   =  @s_srv,
   @s_ssn                   =  @s_ssn,
   @s_term                  =  @s_term,
   @s_user                  =  @s_user,
   @t_debug                 =  @t_debug,
   @t_file                  =  @t_file,
   @t_trn                   =  @t_trn,
   @i_operacion	            =  'R',
   @i_tramite               =  @i_tramite,
   @i_estado                =  @i_estado,
   @i_razon                 =  @i_razon,
   @i_txt_razon             =  @i_txt_razon,
   @i_w_estado              =  @w_estado,
   @i_w_razon               =  @w_razon,
   @i_w_txt_razon           =  @w_txt_razon

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end


  
PRINT 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select 
@o_banco     = @w_banco,
@o_operacion = @w_operacion,
@o_tramite   = @w_tramite
---------------------------------------------

if @w_commit = 'S' 
begin 
   commit tran
   select @w_commit = 'N'
end

return 0


ERROR_PROCESO:
PRINT 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error)
if @w_commit = 'S'
   rollback tran
   
return @w_error

go

