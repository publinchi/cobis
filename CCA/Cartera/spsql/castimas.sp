/************************************************************************/
/*   Archivo:              castimas.sp                                  */
/*   Stored procedure:     sp_castigo_masivo                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   dic. 2004                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Castigo masivo de obligaciones                                     */
/************************************************************************/
/*                               CAMBIOS                                */
/*   FECHA     AUTOR          CAMBIO                                    */
/*   Ene-2015  Elcira Pelaez  NR-0439 Cambio est.Cobranza por parametro */
/************************************************************************/  


use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_castigo_masivo')
   drop proc sp_castigo_masivo
go
SET ANSI_NULLS ON
go
---NR 439 Manejo de la cobranza por parametro 
create proc sp_castigo_masivo
@s_user       varchar(30) = null,
@s_term       varchar(30) = null,
@s_date       datetime    = null,
@s_ofi        int         = null,
@i_banco      cuenta      = null,
@i_proceso    int         = null
as
declare
   @w_error          int,
   @w_op_banco       cuenta,
   @w_op_estado      smallint,
   @w_fecha_proceso  datetime,
   @w_fecha_ult_proceso  datetime,
   @w_msg            varchar(250),
   @w_commit         char(1),
   @w_est_castigado  int,
   @w_cliente        int,
   @w_acta           catalogo,
   @w_causal         catalogo,
   @w_ssn            int,
   @w_cambio_EstCobranza char(1)
   
/*INCIAR VARIABLES DE TRABAJO */   
select 
@w_error  = 0,
@w_commit = 'N',
@w_cambio_EstCobranza ='S'
 
CREATE TABLE #ca_operacion ( 
op_banco             char(24)   NULL, 
op_estado            tinyint    NULL,
op_fecha_ult_proceso datetime   NULL,
op_cliente           int        null,
cm_acta              catalogo   null,
cm_causal            catalogo   null)

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out

select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

---MANEJO DE ESTE CAMBIO POR PARAMETRIZACION
---NR.439 ENE.2015
if exists ( select 1 
            from cobis..cl_catalogo c,
                 cobis..ba_batch
            where c.tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_habilita_camestcobranza')
            and c.codigo = ba_batch
            and ba_arch_fuente like '%sp_cascara_castigo%'
            and c.estado ='V'
            )
BEGIN 
  select @w_cambio_EstCobranza = 'S'
  PRINT 'PROCESO 7072 HABILITADO POR BATCH SE ACTUALIZARA EL ESTADO DE LA COBRANZA '
end
ELSE
begin
  select @w_cambio_EstCobranza = 'N'
    PRINT 'PROCESO 7072 DESHABILITADO POR BATCH  EL ESTADO DE LA COBRANZA NO CAMBIARA '
end
   
   -- ACTUALIZACION DE PARALELISMO
if @i_banco is null begin
   insert into #ca_operacion
   select op_banco, op_estado, op_fecha_ult_proceso, op_cliente, cm_acta, cm_causal
   from   ca_operacion, ca_castigo_masivo
   where  cm_estado = 'I'
   and    op_banco  = cm_banco
   and op_estado  in (1,2,9)
end else begin
   insert into #ca_operacion
   select op_banco, op_estado, op_fecha_ult_proceso, op_cliente, null, null
   from   ca_operacion
   where  op_banco = @i_banco
   and    op_estado  in (1,2,9)
end
   
declare cur_op cursor for select 
op_banco, op_estado, op_fecha_ult_proceso, op_cliente, cm_acta, cm_causal
from   #ca_operacion
for read only
   
open cur_op
   
fetch cur_op  into  
@w_op_banco,       @w_op_estado,     @w_fecha_ult_proceso, @w_cliente, @w_acta, @w_causal
   
while (@@fetch_status = 0) 
begin

   if exists(select 1 from ca_estado
   where es_codigo = @w_op_estado
   and   es_procesa = 'N')
   begin
      select @w_error = 710001, @w_msg = 'ESTADO DE LA OPERACION NO ADMITE CASTIGO'
      goto ERROR1
   end
   
   if @w_op_estado = @w_est_castigado begin
      select @w_error = 710001, @w_msg = 'OPERACION YA CASTIGADA'
      goto ERROR1
   end

	 ---INC. 73988 se traslada de asopera por que dese aca debe ir con la fecha ok
	if @w_fecha_proceso <> @w_fecha_ult_proceso
	begin
	   PRINT'SE debe poner la Obligacion a la fecha del sistema para que quede castigada en esta fecha'
	   ---y las transacciones no palicadas se apliquen anste de cambarle el estado
	    exec @w_error = sp_fecha_valor 
		@s_user              = 'sa',        
		@i_fecha_valor       = @w_fecha_proceso,
		@s_term              = 'Terminal', 
		@s_date              = @w_fecha_proceso,
		@i_banco             = @w_op_banco,
		@i_operacion         = 'F',
		@i_en_linea          = 'N',
		@i_control_fecha     = 'N',
		@i_debug             = 'n'
	
	  if @w_error <> 0 
	  begin
	      PRINT 'error ejecutando sp_fecha_valor @w_error ' + cast (@w_error as varchar)
	      select @w_msg = mensaje  
	      from cobis..cl_errores
		  where numero = @w_error
	      goto ERROR1
	  end 
	   if  @@error <> 0 
	   begin
	      PRINT 'error ejecutando sp  sp_fecha_valor  @w_op_banco  ' + cast ( @w_op_banco as varchar)
	      select @w_error =  708201, @w_msg = 'error ejecutando sp  sp_fecha_valor'
	      goto ERROR1
	   end  
	 
	end
	---INC. 73988 se traslada de asopera por que dese aca debe ir con la fecha ok


   
   exec @w_ssn = sp_gen_sec
   @i_operacion = -3

   select @w_ssn = @w_ssn * -1
   
   if @@trancount = 0 begin
      begin tran          
      select @w_commit = 'S'
   end

   /* SOLO PARA CASTIGOS MASIVOS, REGISTRAR EL CASTIGO EN COBRANZAS Y INGRESAR EL CLIENTE EN LA LISTA INHIBITORIA */
   if  @i_banco is null
   and not exists(select 1 from cob_credito..cr_concordato
   where cn_cliente   = @w_cliente
   and   cn_situacion = 'CAS')
   begin
   
      exec @w_error = cob_credito..sp_concordato 
      @s_date                 = @s_date,  
      @s_user                 = @s_user,
      @s_ssn                  = @w_ssn,
      @s_sesn                 = 1,
      @s_term                 = @s_term,
      @s_srv                  = 'CobisSrv',
      @s_lsrv                 = null,
      @s_ofi                  = @s_ofi,
      @i_operacion            = 'I',
      @t_trn                  = 7999,
      @t_rty                  = '',                
      @i_cliente              = @w_cliente,        
      @i_situacion            = 'CAS',             
      @i_estado               = null,              
      @i_fecha                = null,              
      @i_fecha_fin            = null,              
      @i_cumplimiento         = null,              
      @i_situacion_anterior   = null,              
      @i_acta_cas             = @w_acta,           
      @i_fecha_cas            = @w_fecha_proceso,  
      @i_causal               = @w_causal,
      @i_en_linea             = 'N',
      @o_msg                  = @w_msg out         
       
      if @w_error <> 0 goto ERROR1
      if  (@@error <> 0 )
      begin
          PRINT 'error ejecutando sp cob_credito..sp_concordato  para @w_cliente  ' + cast (@w_cliente as varchar)
	      select @w_error = 708201
	      goto ERROR1
      end
   end
     
   exec @w_error = sp_cambio_estado_op
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @w_op_banco,
   @i_fecha_proceso  = @w_fecha_proceso,
   @i_estado_ini     = @w_op_estado,
   @i_estado_fin     = @w_est_castigado,
   @i_tipo_cambio    = 'C',
   @i_front_end      = 'N',
   @i_en_linea       = 'N',
   @i_cambio_EstCobranza = @w_cambio_EstCobranza,
   @o_msg            = @w_msg out
      
   if @w_error <> 0 goto ERROR1
   if  (@@error <> 0 )
      begin
          PRINT 'error ejecutando sp sp_cambio_estado_op   @w_op_banco  ' + cast ( @w_op_banco as varchar)
	      select @w_error = 708201
	      goto ERROR1
      end
         
   
   update ca_castigo_masivo set    
   cm_estado = 'P'
   where  cm_banco = @w_op_banco
   
   if @@error <> 0 begin
      select @w_error = 710002, @w_msg = 'AL MARCAR EL REGISTRO COMO PROCESADO (tabla: ca_castigo_masivo)'
      goto ERROR1
   end

   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
   
   goto SIGUIENTE
   
   ERROR1:
   
   if @w_commit = 'S' begin
      rollback tran
      select @w_commit = 'N'
   end
   
   select @w_msg = 'CASTIMAS : ' + @w_msg
         
   insert into ca_errorlog(
   er_fecha_proc, er_error,     er_usuario,
   er_tran,       er_cuenta,    er_descripcion,
   er_anexo)
   values (
   @s_date,      @w_error,     @s_user,
   0,            @w_op_banco,  @w_msg,
   '')
      
   SIGUIENTE:
      
   fetch cur_op into  
   @w_op_banco,       @w_op_estado,     @w_fecha_ult_proceso, @w_cliente, @w_acta, @w_causal
   
end
close cur_op
deallocate cur_op
   
return 0

go

