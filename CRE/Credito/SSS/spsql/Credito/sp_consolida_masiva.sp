/***********************************************************************/
/*      Archivo:                      sp_consolida_masiva.sp           */
/*      Stored procedure:             sp_consolida_masiva              */
/*      Base de Datos:                cob_workflow                     */
/*      Producto:                     Castigo                          */
/*      Disenado por:                 Geovanny Duran                   */
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
/*  Ejecuta proceso de consolidacion de castigo de forma masiva        */
/*                                                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/*      01/Feb/2017     Geovanny Duran     Emision Inicial             */
/*                                                                     */
/***********************************************************************/
use cob_credito
go
if exists (select * from sysobjects where name = 'sp_consolida_masiva')
	drop procedure sp_consolida_masiva
go

create proc sp_consolida_masiva (
	@s_ofi           smallint, 
	@s_user          varchar(12),
	@s_date          datetime,
	@t_trn           int
	--@o_id_resultado  smallint = null out  
)as

declare
    @w_date_rate            datetime,
	@w_tramite		        int,
	/*campos para sp_castigo_operaciones*/
	@w_id_inst_proc         int,
	@w_imposibilidad_pago   varchar(255),
	@w_imposibilidad_pago2  varchar(255),
	@w_imposibilidad_pago3  varchar(255),
	@w_razones              varchar(255),
	@w_razones2             varchar(255),
	@w_razones3             varchar(255),
	@w_num_banco	        varchar(30),
	@w_sp_name              varchar(25),
	@w_check                char(1),
	@w_error                INT
	

select  @w_sp_name = 'sp_consolida_masiva'

if @t_trn <> 21799
begin --Tipo de transaccion no corresponde
    select @w_error = 2101006
      return @w_error
end

select @w_tramite = 0
/* Obtengo el numero de operacion*/
select @w_date_rate = max(ca_fecha_corte) 
  from cob_credito..cr_tr_castigo

/* Recorro registros*/
while 1=1 
begin
   -- SETEO VARIABLES
   select @w_id_inst_proc    = null,
      @w_imposibilidad_pago	 = null,
	  @w_imposibilidad_pago2 = null,
	  @w_imposibilidad_pago3 = null,
	  @w_razones	         = null,
	  @w_razones2	         = null,
      @w_razones3	         = null,
	  @w_check               = null
   
   set rowcount 1
   select @w_tramite            = ca_tramite,
        @w_id_inst_proc         = ca_int_proceso,
		@w_num_banco            = ca_banco,
        @w_imposibilidad_pago	= ca_imposibilidad_pago,
		@w_imposibilidad_pago2	= ca_imposibilidad_pago2,
		@w_imposibilidad_pago3	= ca_imposibilidad_pago3,
		@w_razones	= ca_razones,
		@w_razones2	= ca_razones2,
		@w_razones3	= ca_razones3,
		@w_check    = isnull(cc_check,'N')
     from cob_credito..cr_tr_castigo, cob_cartera..ca_candidata_castigo
    where ca_fecha_corte = @w_date_rate 
      and cc_fecha_corte = ca_fecha_corte
      and cc_banco = ca_banco
      and ca_tramite > @w_tramite
	order by ca_tramite
	
	if @@rowcount = 0 begin
       set rowcount 0
       break
    end
	set rowcount 0
	
	if @w_check = 'S'
	begin
		exec cob_credito..sp_castigo_operaciones
			 @t_trn           = 21865,
			 @i_operacion     = 'U',
			 @i_int_proceso   = @w_id_inst_proc,
			 @i_num_operacion = @w_num_banco, --Valores necesarios para el sp interno
			 @i_tramite       = 0,       --Valores necesarios para el sp interno
			 @i_estado        = 'R',
			 @i_imposibilidad_pago	= @w_imposibilidad_pago,
			 @i_imposibilidad_pago2	= @w_imposibilidad_pago2,
			 @i_imposibilidad_pago3	= @w_imposibilidad_pago3,
			 @i_razones	      = @w_razones,
			 @i_razones2	  =	@w_razones2,
			 @i_razones3	  =	@w_razones3

		set @w_error = @@error
		if  @w_error<> 0
		BEGIN
		   --select @o_id_resultado = 0
		   exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
		   return @w_error
		end
	end
	else
	begin
		 exec cob_credito..sp_castigo_operaciones
			  @t_trn        	=   21865,
			  @i_operacion 	    = 	'U',
			  @i_int_proceso    =  	@w_id_inst_proc, 
			  @i_tramite =  @w_tramite,
			  @i_num_operacion = @w_num_banco,
			  @i_estado         =  	'D',
				  /*Data que se mantiene*/
			  @i_imposibilidad_pago		=	@w_imposibilidad_pago,
			  @i_imposibilidad_pago2	=	@w_imposibilidad_pago2,
			  @i_imposibilidad_pago3	=	@w_imposibilidad_pago3,
			  @i_razones	=	@w_razones,
			  @i_razones2	=	@w_razones2,
			  @i_razones3	=	@w_razones3
			  
		 set @w_error = @@error
		 if  @w_error<> 0
		 BEGIN
		    --select @o_id_resultado = 0
		    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
		    return @w_error
		 end
		 
		 --CAMBIO ESTADO DE TRAMITE
         update cob_credito..cr_tramite
            set tr_estado = 'Z'
           from cob_credito..cr_tramite
         where tr_tramite = @w_tramite
		   
		 
		 --SE ELIMINA EL LOTE
		 update cob_cartera..ca_candidata_castigo
		 set cc_estado_castigo = 99
		 where cc_fecha_corte = @w_date_rate
		   and cc_banco = @w_num_banco
		 
	end
		
end		
 


--select @o_id_resultado

return 0                                                                                                                                                                                                                  

go
