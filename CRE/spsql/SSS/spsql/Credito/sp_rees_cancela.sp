/***********************************************************************/
/*      Archivo:                        sp_rees_cancela.sp             */
/*      Stored procedure:               sp_rees_cancela                */
/*      Base de Datos:                  cob_pac                        */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Geovanny Duran                 */
/***********************************************************************/
/*        IMPORTANTE                                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "COBISCORP", representantes exclusivos para el Ecuador de la       */
/*  "COBISCORP CORPORATION".                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier alteracion o agregado hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de la            */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Cambia de estado a la instancia para habilitar la operacion a otro */
/*  proceso de reestructuracion                                        */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*      06/Ene/2017     Geovanny Duran          Emision Inicial        */
/***********************************************************************/
use cob_credito
go

 if exists (select 1 from sysobjects where name = 'sp_rees_cancela')
    drop procedure sp_rees_cancela
go

create proc sp_rees_cancela
@s_user        	varchar(30) 	= null,
@s_sesn         int             = null,
@s_term        	varchar(30) 	= null,
@s_date        	datetime	    = null,
@i_campo_2      varchar(255)    = null

as 

/* Declaraciones de variables de operacion */
declare @w_sp_name	varchar(30),
	@w_date		datetime,
	@w_msg		varchar(50),
	@w_error	int,
	@w_wf       varchar(64),
	@w_cod_proc smallint,
	@w_max_rees tinyint,
	@w_num_rees tinyint,
	@w_numero_operacion  varchar(50)
	
/*-- setear variables de operacion */
select @w_sp_name = 'sp_rees_cancela'
select @w_date = fp_fecha from cobis..ba_fecha_proceso


/*-- Lee parametros */
-- NEMONICO DE FLUJO
select @w_wf = pa_char from cobis..cl_parametro
 where pa_nemonico = 'SOLREE'
   and pa_tipo = 'C'
   and pa_producto = 'CRE'
   
/*-- Obtenemos Proceso*/
select @w_cod_proc = pr_codigo_proceso
  from cob_workflow..wf_proceso
 where pr_producto = 'CRR'
   and pr_nemonico = @w_wf

--Recupero el numero de operacion a renovar
select @w_numero_operacion = @i_campo_2
  
/*-- Se valida si se encuentra en proceso de reestructuracion*/
if exists ( select 1 from cob_workflow..wf_inst_proceso
                    where io_codigo_proc = @w_cod_proc
                      and io_campo_2 = @w_numero_operacion)
begin
   update cob_workflow..wf_inst_proceso
      set io_estado = 'CAN'
    where io_codigo_proc = @w_cod_proc
      and io_campo_2 = @w_numero_operacion 
	  and io_estado = 'EJE'
  
   exec cobis..sp_cerror
        @t_debug = 'N',
        @t_file  = ' ', 
        @t_from  = @w_sp_name,
        @i_num   = 7300102
      return 1
end

/*-- Se valida tipo de operacion o clase de cartera*/
return 0
go
