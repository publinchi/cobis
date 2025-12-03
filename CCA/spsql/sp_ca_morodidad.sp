/************************************************************************/
/*    Archivo:                  sp_ca_morosidad.sp                      */
/*    Stored procedure:         sp_ca_morosidad                         */
/*    Base de datos:            cob_cartera                             */
/*    Producto:                 Cartera                                 */
/*    Disenado por:             Jorge Escobar                           */
/*    Fecha de escritura:       13/Nov/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA",  representantes  exclusivos  para  el Ecuador de la     */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Proceso que devuelve el valor de la variable de morodidad de un   */
/*    cliente                                                           */
/************************************************************************/
/*				MODIFICACIONES				*/
/*    FECHA		AUTOR			RAZON			*/
/*  22/11/2019         EMP-JJEC                Creaciòn                 */
/************************************************************************/
use cob_cartera
go
 
if exists (select * from sysobjects where name = "sp_ca_morosidad")
  drop proc sp_ca_morosidad
go

create proc sp_ca_morosidad 
@s_user          login        = NULL,
@s_term          descripcion  = NULL,
@s_ofi           smallint     = NULL,
@s_date          datetime     = NULL,
@i_cliente       int          = NULL,   --Cliente
@o_id_resultado  char(1)      output
as

declare
@w_est_cancelado                tinyint,
@w_est_credito                  tinyint,
@w_est_anulado                  tinyint,
@w_est_novigente                tinyint,
@w_est_vigente                  tinyint,
@w_est_vencido                  tinyint,
@w_mora                         char(1),
@w_nrows                        int,
@w_operacionca                  int,
@w_sec_previo                   int,
------
@w_variables varchar(255),
        @w_error int,
        @w_return_variable varchar(255),
        @w_return_results  varchar(255),
        @w_last_condition_parent varchar(10)

select @w_mora = 'N' 

if exists (select 1 from ca_operacion 
            where op_cliente = @i_cliente
              and op_estado not in (@w_est_cancelado, @w_est_novigente, @w_est_credito, @w_est_anulado)
              and op_toperacion = 'VIVTCASA')
begin

   select @w_nrows = 1, 
          @w_sec_previo = 0

   while (@w_nrows > 0) 
   begin 
     select top 1
     @w_operacionca   = op_operacion,
     @w_sec_previo    = op_operacion
     from ca_operacion 
     where op_cliente = @i_cliente
       and op_estado not in (@w_est_cancelado, @w_est_novigente, @w_est_credito, @w_est_anulado)
       and op_toperacion = 'VIVTCASA'
       and op_operacion > @w_sec_previo
     order by op_operacion
           
     if @@rowcount = 0 break
     
     -- Poner el codigo que se quiera evaluar para cada operacion  
     if exists (select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido)
        select @w_mora = 'S'

   end
end

select @o_id_resultado = @w_mora

return 0

go

