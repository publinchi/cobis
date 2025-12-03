/*************************************************************************/
/*   Archivo:              sp_aprueba_gar.sp                             */
/*   Stored procedure:     sp_aprueba_gar                                */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:                                                       */
/*   Fecha de escritura:                                                 */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las convenciones internacionales de propiedad inte-        */
/*   lectual. Su uso no autorizado dara derecho a MACOSA para        */
/*   obtener ordenes de secuestro o retencion y para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Aprueba el modificatorio de garantías para pasar                   */
/*	 los registros de la cr_gar_anteriores a la cr_gar_propuesta         */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*                                                                       */
/*************************************************************************/
USE cob_credito
GO

IF OBJECT_ID ('dbo.sp_aprueba_gar') IS NOT NULL
	DROP PROCEDURE dbo.sp_aprueba_gar
GO

CREATE PROCEDURE dbo.sp_aprueba_gar(
   @s_ssn            int         = NULL,   
   @s_user           login       = NULL,
   @s_term           varchar(30) = NULL,
   @s_ofi            smallint    = NULL,
   @s_srv            varchar(30) = NULL,
   @s_lsrv           varchar(30) = NULL,     
   @s_date           datetime    = NULL,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(14) = null,
   @i_tramite        int         = null,
   @o_resultado      int         = null out
)
as

declare
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_tr_asociado        int,
   @w_cliente            int,
   @w_num_operacion      cuenta,
   @w_gar_anterior       varchar(64),
   @w_gar_nueva          varchar(64),
   @w_ab_ce_ant          char(1),
   @w_ab_ce_nue          char(1),
   @w_est_anterior       char(1),
   @w_est_nueva          char(1),
   @w_resultado          int,
   @w_estado_fin         char(1),
   @w_porcentaje         float,
   @w_concepto           catalogo,
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_custodia           int,
   @w_val_actual         money,
   @w_return             int

select @w_sp_name   = 'sp_aprueba_gar',
       @w_resultado = 0

--Validacion de campos NULL
if @i_tramite is NULL
begin
   --Campos NOT NULL con valores nulos
   select @o_resultado = 2
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file, 
   @t_from  = @w_sp_name,
   @i_num   = 2101001
  
   return  2101001
end

--Trae el cliente de la modificacion de la garantia, y el tramite asociado de la operacion
SELECT @w_cliente = tr_cliente
  FROM cob_credito..cr_tramite
 WHERE tr_tramite = @i_tramite
 
set rowcount 0
 
DECLARE cur_aprueba_gar CURSOR FOR
SELECT ga_gar_anterior,   
       ga_gar_nueva,
       ga_operacion
  FROM cob_credito..cr_gar_anteriores
 WHERE ga_tramite = @i_tramite
 ORDER BY ga_gar_anterior

OPEN cur_aprueba_gar

FETCH cur_aprueba_gar INTO 
   @w_gar_anterior,
   @w_gar_nueva,
   @w_num_operacion

WHILE @@FETCH_STATUS = 0  
begin
   /*if (@@sqlstatus = 1)
   begin
     select @o_resultado = 2
      --Error en recuperacion de datos del cursor
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2902900 
      
      return 2902900
   end
*/

   SELECT @w_tr_asociado = op_tramite  --PQU 2017-09-04
   FROM cob_cartera..ca_operacion
   WHERE op_banco = @w_num_operacion

   --begin tran

	
   --Elimina Garantias
   if @w_gar_nueva is null
   begin
      --Cobertura de la garantia y estado
     

      select   @w_est_anterior  = cu_estado,
               @w_concepto    = cu_tipo,
               @w_filial      = cu_filial,
               @w_sucursal    = cu_sucursal,
               @w_custodia    = cu_custodia,
               @w_porcentaje  = isnull(cu_porcentaje_cobertura, 0),
               @w_val_actual  = cu_valor_actual,
               @w_ab_ce_ant    = cu_abierta_cerrada
         from cob_custodia..cu_custodia
         where cu_codigo_externo = @w_gar_anterior
      
      --Si la garantia es abierta, se pone cancelada en gar_propuesta
      --Pone cancelado el registro en gar_propuesta
         update cob_credito..cr_gar_propuesta
            set gp_est_garantia = 'C'
          where gp_tramite  = @w_tr_asociado
            and    gp_garantia = @w_gar_anterior
         if @@error != 0
         begin
            select @o_resultado = 2
            CLOSE cur_aprueba_gar
            DEALLOCATE cur_aprueba_gar
            --No se pudieron actualizar las modificaciones de garantias
            exec cobis..sp_cerror 
            @t_debug = @t_debug, 
            @t_file  = @t_file, 
            @t_from  = @w_sp_name, 
            @i_num   = 2110282
            
            return 2110282--1905008
         end

         select @w_estado_fin = 'X'

         if @w_est_anterior = 'P'
             select @w_estado_fin = 'A'

         if @w_est_anterior in ('V','F')
             select @w_estado_fin = 'X'


         exec @w_return = cob_custodia..sp_cambios_estado
              @s_user 		= @s_user,
              @s_date 		= @s_date,
              @s_term 		= @s_term,
              @s_ofi 	        = @s_ofi,
              @s_ssn 		= @s_ssn,
              @i_operacion 	= 'I',
              @i_estado_ini 	= @w_est_anterior,
              @i_estado_fin 	= @w_estado_fin,
              @i_codigo_externo = @w_gar_anterior,
              @i_banderafe 	= 'S'

        if @w_return !=0
        begin
            select @o_resultado = 2
            CLOSE cur_aprueba_gar
            DEALLOCATE  cur_aprueba_gar
            --No se pudieron actualizar las modificaciones de garantias
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2110282

            return @w_return
            --rollback tran
        end

        if @w_estado_fin <> 'A'                             --Anulado
        begin
            exec @w_return = cob_custodia..sp_cancela
                 @s_user 		= @s_user,
                 @s_date 		= @s_date,
                 @s_term 		= @s_term,
                 @s_ofi 	        = @s_ofi,
                 @s_ssn 		= @s_ssn,
                 @i_filial         = @w_filial,
                 @i_sucursal       = @w_sucursal,
                 @i_tipo_cust      = @w_concepto,
                 @i_custodia       = @w_custodia,
                 @i_consulta       = 'N',
                 @i_pasar          = 'S',
                 @i_login          = @s_user,
                 @t_trn            = 19624,
                 @i_operacion 	= 'S',
                 @i_modo   	= 0
            if @w_return !=0
            begin
                select @o_resultado = 2
                CLOSE cur_aprueba_gar
                DEALLOCATE cur_aprueba_gar
                --No se pudieron actualizar las modificaciones de garantias
                exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 2110283
                   
                 return @w_return
                 --rollback tran
            end
        end   --Estado diferente de Anulado
      


      select @w_resultado = 1
   end
   else
   --Creacion de garantias
   begin
      --Obtener estado y cobertura de la garantia NUEVA
      
         select @w_est_nueva = convert(char(1),cu_estado),
               @w_concepto    = cu_tipo,
               @w_filial      = cu_filial,
               @w_sucursal    = cu_sucursal,
               @w_custodia    = cu_custodia,
               @w_porcentaje  = isnull(cu_porcentaje_cobertura, 0),
               @w_val_actual  = cu_valor_actual,
               @w_ab_ce_nue    = cu_abierta_cerrada
         from cob_custodia..cu_custodia
         where cu_codigo_externo = @w_gar_nueva

      --Cambiar el estado de las propuestas
         if @w_est_nueva = 'P'
         begin
            select @w_estado_fin = 'V'
  
            exec @w_return = cob_custodia..sp_cambios_estado
              @s_user 		= @s_user,
              @s_date 		= @s_date,
              @s_term 		= @s_term,
              @s_ofi 	        = @s_ofi,
              @s_ssn 		= @s_ssn,
              @i_operacion 	= 'I',
              @i_estado_ini 	= @w_est_nueva,
              @i_estado_fin 	= @w_estado_fin,
              @i_codigo_externo = @w_gar_nueva,
              @i_banderafe 	= 'S'

            if @w_return !=0
            begin
               select @o_resultado = 2
               CLOSE cur_aprueba_gar
               DEALLOCATE cur_aprueba_gar
               --No se pudieron actualizar las modificaciones de garantias
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2110282

                return @w_return
                --rollback tran
            end
            select @w_est_nueva = 'V'
         end
      --Las garantias deben estar vigentes porque anteriormente se hizo el cambio de estado
      if @w_est_nueva <> 'V'
      begin
         select @o_resultado = 2
         CLOSE cur_aprueba_gar
         DEALLOCATE cur_aprueba_gar
         --No se pudieron actualizar las modificaciones de garantias
         exec cobis..sp_cerror 
         @t_debug = @t_debug, 
         @t_file  = @t_file, 
         @t_from  = @w_sp_name, 
         @i_num   = 2110284
--         rollback tran
         
         return 2110284--1905008
      end
      if @w_num_operacion is null and @w_ab_ce_nue='C'
      begin
         select @o_resultado = 2
         CLOSE cur_aprueba_gar
         DEALLOCATE  cur_aprueba_gar
         --No se pudieron actualizar las modificaciones de garantias
         exec cobis..sp_cerror 
         @t_debug = @t_debug, 
         @t_file  = @t_file, 
         @t_from  = @w_sp_name, 
         @i_num   = 2110285
--         rollback tran
         
         return 2110285--1905008
      end 
      --Inserto la garantia en el tramite indicado si existe el tramite
      if @w_tr_asociado is not null
      begin
         insert into cob_credito..cr_gar_propuesta 
                     (gp_tramite,       gp_garantia,      gp_clasificacion,   gp_exceso,
                      gp_monto_exceso,  gp_abierta,       gp_deudor,          gp_est_garantia, 
					  gp_porcentaje, gp_valor_resp_garantia ,gp_fecha_mod)  --PQU
               values(@w_tr_asociado,   @w_gar_nueva,     'a',                'N', 
                      0,                @w_ab_ce_nue,     @w_cliente,         @w_est_nueva, 
					  @w_porcentaje,  round(@w_val_actual * isnull(@w_porcentaje, 0) / 100, 2),getdate()) --PQU
         if @@error != 0 
         begin
            select @o_resultado = 2
            CLOSE cur_aprueba_gar
            DEALLOCATE  cur_aprueba_gar

            exec cobis..sp_cerror 
            @t_debug = @t_debug, 
            @t_file  = @t_file, 
            @t_from  = @w_sp_name, 
            @i_num   = 2110286
--            rollback tran
               
            return 2110286 --1905008           
         end
      end
      select @w_resultado = 1
   end
--   commit tran
   FETCH cur_aprueba_gar INTO 
      @w_gar_anterior,
      @w_gar_nueva,
      @w_num_operacion
end  -- fin del while

CLOSE cur_aprueba_gar
DEALLOCATE cur_aprueba_gar

if (@w_resultado = 1)
  select @o_resultado = 1
else
   select @o_resultado = 2

return 0
                                
                                                                                                                                                                                                                                               
                                                                                                                                                                                         

GO

