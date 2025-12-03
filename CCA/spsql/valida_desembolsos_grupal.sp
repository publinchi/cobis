/******************************************************************************/
/*      Archivo:                valida_desembolsos_grupal.sp                  */
/*      Stored procedure:       sp_valida_desembolsos_grupal                  */
/*      Base de datos:          cob_cartera                                   */
/*      Producto:               Cartera                                       */
/*      Disenado por:           Juan Carlos Miranda                           */
/*      Fecha de escritura:     Oct. 2021                                     */
/******************************************************************************/
/*                                 IMPORTANTE                                 */
/* Este programa es parte de los paquetes bancarios propiedad de COBISCorp.   */
/* Su uso no autorizado queda expresamente prohibido asi como cualquier       */
/* alteracion o agregado hecho por alguno de usuarios sin el debido           */
/* consentimiento por escrito de la Presidencia Ejecutiva de COBISCorp        */
/* o su representante.                                                        */
/******************************************************************************/
/*                              PROPOSITO                                     */
/* Realizar un programa que permita recalcular el monto de rubros tipo        */
/* porcentaje y calculado                                                     */
/******************************************************************************/
/*                              MODIFICACIONES                                */
/*  FECHA       VERSION        AUTOR                 RAZON                    */
/*  19/10/2021          Juan Carlos Miranda      Version Inicial              */
/*                                                                            */
/******************************************************************************/

use cob_cartera
go
IF OBJECT_ID ('sp_valida_desembolsos_grupal') IS NOT NULL
        drop proc sp_valida_desembolsos_grupal
go
create proc sp_valida_desembolsos_grupal
        @t_show_version     bit         = 0,    -- show the version of the stored procedure  
        @i_tramite          VARCHAR(20),  
        @s_user             login,
        @s_term             varchar(30) = null,
        @s_ofi              smallint,  
        @s_date             datetime     = NULL,
        @o_validacion       VARCHAR(100)  out 
as
declare 
	    @w_return            int,
		@w_monto_total       money,
	    @w_operacion_ini     int, 
	    @w_operacion_fin     INT,
	    @w_monto             MONEY,
	    @w_monto_desembolsar MONEY,
	    @w_cliente           INT,
	    @w_resultado         VARCHAR(100),
	    @w_contador          INT,
	    @w_cad               INT,
	    @w_nombre            VARCHAR(18)
	    
			
		if @t_show_version = 1
		begin
		   print 'Stored procedure sp_valida_desembolsos_grupal, Version 4.0.0.0'
		   return 0
		end
				
		if not exists(select 1 from cob_credito..cr_tramite_grupal, cob_credito..cr_tramite
		              where tg_tramite = tr_tramite and tr_tramite= @i_tramite and tr_estado = 'A')
		if @@rowcount = 0
		begin
			return 2110131
		end
			
        select @w_monto_total = tr_monto FROM cob_credito..cr_tramite where tr_tramite =  @i_tramite
        
        
        SELECT @w_resultado = ''

        select @w_operacion_ini = min(tg_operacion) from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite    
        select @w_operacion_fin = max(tg_operacion) from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite

         
        while @w_operacion_ini <= @w_operacion_fin
        begin
        
           select @w_cliente = tg_cliente
           from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite 
           and tg_prestamo = @w_operacion_ini
           
                      
           select @w_nombre = en_nombre +' '+ p_p_apellido FROM cobis..cl_ente WHERE en_ente = @w_cliente
           
           select @w_monto = op_monto FROM ca_operacion WHERE op_operacion = @w_operacion_ini
           
           select @w_monto_desembolsar = isnull(sum(dm_monto_mop),0) FROM ca_desembolso WHERE dm_operacion = @w_operacion_ini
           
           
           IF @w_monto_desembolsar <> @w_monto
           begin 
             select @w_cad = len(@w_resultado)
             IF (@w_cad = 0)
              begin
                    select @w_resultado = CONVERT(VARCHAR(5),@w_cliente) + '-' + @w_nombre
              end
             else
              select @w_resultado = @w_resultado + ';' + CONVERT(VARCHAR(5),@w_cliente) + '-' + @w_nombre
           end
        
           select @o_validacion = @w_resultado
        
        
        if  @w_operacion_ini = @w_operacion_fin
        break
 
          select @w_operacion_ini = min(tg_operacion) from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite  
                 and tg_operacion > @w_operacion_ini
                 
        end
		

return 0
go

        