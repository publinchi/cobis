/************************************************************************/
/*	Archivo:		refvmas.sp    				*/
/*	Stored procedure:	sp_reversa_fechaval_masivos		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera			                */
/*	Disenado por:  		Epelaez   			        */
/*	Fecha de escritura:	Enero. 2002. 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento que realiza el reverso masivo o aplica fecha val  */
/*      masiva a un grupo de operaciones de cartera cargadas en la tabla*/
/*      ca_revfv_masivos para una fecha de proceso dada			*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_revfv_masivos')
   DROP TABLE ca_revfv_masivos
go

CREATE TABLE ca_revfv_masivos (rf_banco           cuenta    not null,
                               rf_secuencial      int           null,  --Para reversos
                               rf_fecha_val       datetime      null,  --Para fecha valor
                               rf_fecha_mov       datetime      null,  --Para Reversos
                               rf_fecha_proceso   datetime      null,
			       rf_estado_reg      char(1)       null)  --Se actualiza al procesar


go


if exists (select 1 from sysobjects where name = 'sp_reversa_fechaval_masivos')
   drop proc sp_reversa_fechaval_masivos
go

create proc sp_reversa_fechaval_masivos(
@s_user		     	login,
@s_term		     	varchar(30),
@s_date		     	datetime,
@s_ofi		     	smallint,
@i_operacion            char(1),                 --(F)Fecha Valor (R)Reversa
@i_observacion          varchar(255),
@i_susp_causacion       char(1)      = 'N',      --Para no ejecutar el batch por suspencion de causacion
@i_fecha_proceso        datetime
)   
as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_banco                cuenta, 
@w_secuencial           int,
@w_fecha_val            datetime,
@w_fecha_mov            datetime


select @w_sp_name  = 'sp_reversa_fechaval_masivos'


/* CARGAR LA TABLA ca_revfv_masivos */
/****
insert into ca_revfv_masivos
select op_banco, re_secuencial, '03/04/2002', re_fecha, '03/15/2002', null
from ca_operacion, ca_reajuste
where op_estado not in (0,3,4,6,98,99,10)
and re_operacion = op_operacion
and re_fecha = '03/04/2002'
and op_toperacion = 'CVCASURA0'
*********************************/

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/
/**
insert into ca_revfv_masivos
select a.tr_banco, a.tr_secuencial, '03/27/2002', a.tr_fecha_ref, '04/12/2002', null
from ca_transaccion a, suspensos_tmp b, ca_operacion
where a.tr_tran = 'HFM'
and a.tr_fecha_mov = '03/27/2002'
and a.tr_banco = b.tr_banco
--and tr_operacion = 6013
and a.tr_operacion = op_operacion
and op_fecha_ult_proceso > '04/01/2002'
**/


/*
insert into ca_revfv_masivos
select tr_banco, tr_secuencial, '03/04/2002', tr_fecha_ref, '03/18/2002', null
from ca_transaccion
where tr_toperacion = 'CVCASURA0'
and tr_tran = 'REJ'
and tr_fecha_mov = '03/14/2002'
and tr_fecha_ref = '03/04/2002'
*/
/*
insert into ca_revfv_masivos
select tr_banco, tr_secuencial, '03/04/2002', tr_fecha_ref, '03/15/2002', null
from ca_transaccion
where tr_toperacion = 'CVFORFACA0'
and tr_tran = 'REJ'
and tr_fecha_mov = '03/18/2002'
and tr_fecha_ref = '03/14/2002'
*/

if not exists(select 1 from  ca_revfv_masivos
              where rf_fecha_proceso = @i_fecha_proceso) begin
   PRINT '(revfvmas.sp)  ERROR!!! fecha proceso no coinside o no hay datos'
   return 0
end 

/* CURSO PARA LEER TABLA ca_revfv_masivos */
declare cursor_operacion cursor for
select 
rf_banco,
rf_secuencial,
rf_fecha_val,
rf_fecha_mov
from  ca_revfv_masivos
where rf_fecha_proceso = @i_fecha_proceso
and rf_estado_reg = null
order by rf_banco
for read only

open cursor_operacion

fetch cursor_operacion into 
@w_banco,
@w_secuencial,
@w_fecha_val,
@w_fecha_mov

while @@fetch_status = 0 begin   

   if @@fetch_status = -1 begin    
      PRINT '(revfvmas.sp)  ERROR!!! en lectura del cursor (cursor_operacion)'
      return 0
   end   
     
     /*VALIDACION DE OPERACION f o R */

      if @i_operacion = 'F' and  @w_fecha_val = null begin
         select @i_observacion  = 'PROCESO FECHA VALOR NO ACEPTA fehca_val en NULL'
         goto ERROR
      end

      if @i_operacion = 'R' and  (@w_fecha_mov = null or @w_secuencial = null) begin
         select @i_observacion  = 'PROCESO REVERSO NO ACEPTA fehca_mov o sec en NULL'
         goto ERROR
      end

      PRINT '(revfvmas.sp)  Operacion que va @w_banco' + @w_banco

/** PARCHADO HASTA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/
/**

      exec @w_return       = sp_fecha_valor_hfm
      @s_user		   = @s_user,
      @s_term		   = @s_term,
      @s_date		   = @s_date,
      @s_ofi		   = @s_ofi,
      @i_fecha_valor       = @w_fecha_val,
      @i_banco             = @w_banco,
      @i_secuencial        = @w_secuencial,
      @i_operacion         = @i_operacion, 
      @i_observacion       = @i_observacion,
      @i_susp_causacion    = @i_susp_causacion,
      @i_fecha_mov         = @w_fecha_mov

      if @w_return <> 0 begin
         select @w_error = @w_return
         PRINT '(revfvmas.sp) salio de sp_fecha_valor por Error'
         goto ERROR
      end 
      else  begin
         PRINT '(revfvmas.sp) salio de sp_fecha_valor Ok.'
        update ca_revfv_masivos
        set rf_estado_reg = 'P'
        where rf_banco = @w_banco

      end
**/


   goto SIGUIENTE

   ERROR:  
                                                    
   exec sp_errorlog                                             
   @i_fecha     = @i_fecha_proceso,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7000, 
   @i_tran_name = @w_sp_name,
   @i_rollback  = 'N',  
   @i_cuenta= @w_banco,
   @i_descripcion = @i_observacion
   goto SIGUIENTE


 SIGUIENTE:
 fetch cursor_operacion into 
 @w_banco,
 @w_secuencial,
 @w_fecha_val,
 @w_fecha_mov

end /* cursor_operacion */
close cursor_operacion
deallocate cursor_operacion

return 0

go


