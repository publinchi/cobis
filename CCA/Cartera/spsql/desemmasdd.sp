/************************************************************************/
/*   Archivo:              desemmasdd.sp                                */
/*   Stored procedure:     sp_desembolsos_masivos_dd                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/*   Fecha de escritura:   nov  de 2005                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Este programa desembolsa las operaciones de Documetnos descontados */
/*                                                                      */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*     FECHA        AUTOR                    RAZON                      */
/*    24/Jun/2022     KDR              Nuevo parámetro sp_liquid        */
/*                                                                      */
/************************************************************************/



use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desembolsos_masivos_dd')
   drop proc sp_desembolsos_masivos_dd
go

create proc sp_desembolsos_masivos_dd (
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_ofi            smallint,
   @i_fecha_proceso  datetime
)
as
declare
   @w_sp_name                 varchar(30),
   @w_error                   int,
   @w_op_operacion_A          int,
   @w_op_tramite_A            int,
   @s_ssn                     int,
   @s_sesn                    int,
   @w_op_banco_A              cuenta,
   @w_banco                   cuenta,
   @w_op_banco_e              cuenta,
   @w_op_fecha_ini_A          datetime




select   @w_sp_name    = 'sp_desembolsos_masivos_dd'
         


declare
   cursor_desembolso cursor
   for select distinct op_operacion, op_banco, op_tramite,  op_fecha_ini

    from   ca_desembolso,   
           ca_operacion
    where  dm_operacion   = op_operacion
    and    op_fecha_ini  <= @i_fecha_proceso
    and    op_estado      = 0      
    and    op_tipo       = 'D'      
 
    for read only

open cursor_desembolso

fetch cursor_desembolso
into  @w_op_operacion_A,  @w_op_banco_A,   @w_op_tramite_A, @w_op_fecha_ini_A


--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin

      BEGIN TRAN
      
         if exists ( select 1 from ca_operacion_tmp
         where opt_operacion = @w_op_operacion_A)
         begin
            exec @w_error = sp_borrar_tmp
                 @s_user       = @s_user,
                 @s_sesn       = @s_sesn,
                 @s_term       = @s_term,
                 @i_desde_cre  = 'N',
                 @i_banco      = @w_op_banco_A
            
            if @w_error != 0
            begin
               PRINT 'desemmasdd.sp salio por error de sp_borrar_tmp banco' + @w_banco
               select @w_op_banco_e = @w_op_banco_A
               goto ERROR
            end
         end

         exec @w_error     = sp_pasotmp
              @s_user            = @s_user,
              @s_term            = @s_term,
              @i_banco           = @w_op_banco_A,
              @i_operacionca  = 'S',
              @i_dividendo    = 'S',
              @i_amortizacion = 'S',
              @i_cuota_adicional = 'S',
              @i_rubro_op     = 'S',
              @i_relacion_ptm = 'S',
              @i_nomina       = 'S',
              @i_acciones     = 'S',
              @i_valores      = 'S'
         
         if @w_error != 0
         begin
            PRINT 'liquidades.sp salio por error de sp_pasotmp banco' + @w_banco
            goto ERROR
         end
         

            exec @s_ssn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @s_sesn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @w_error = sp_liquida
                 @s_ssn             = @s_ssn,
                 @s_sesn            = @s_sesn,
                 @s_user            = @s_user,
                 @s_date            = @s_date,
                 @s_ofi             = @s_ofi,
                 @s_rol             = 1,
                 @s_term            = @s_term,
                 @i_banco_ficticio  = @w_op_banco_A,
                 @i_banco_real      = @w_op_banco_A,
                 @i_afecta_credito  = 'N',
                 @i_fecha_liq       = @w_op_fecha_ini_A,
                 @i_externo         = 'N',
				 @i_desde_cartera   = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
                 @i_banderafe       = 'N'
      
                 if @w_error <> 0
                 begin
                    select @w_op_banco_e = @w_op_banco_A
                    goto ERROR
                 end
   
   
            -- NUEVOS DATOS DESPUES DEL DESEMBOLSO DE LA ACTIVA  PARA ACTUALIZAR CREDITO 

            select @w_banco    = op_banco
            from   cob_cartera..ca_operacion
            where  op_operacion    = @w_op_operacion_A
      
            update cob_credito..cr_tramite
            set    tr_numero_op       = @w_op_operacion_A,     
                   tr_numero_op_banco = @w_banco
            where  tr_tramite         = @w_op_tramite_A
      
            if @@error != 0
            begin
               select @w_error = 2105051
               select @w_op_banco_e =  @w_op_banco_A
               goto ERROR
            end

           exec @w_error = sp_borrar_tmp
                 @s_user       = @s_user,
                 @s_sesn       = @s_sesn,
                 @s_term       = @s_term,
                 @i_desde_cre  = 'N',
                 @i_banco      = @w_op_banco_A
            
            if @w_error != 0
            begin
               PRINT 'desemmasdd.sp salio por error de sp_borrar_tmp banco' + @w_banco
               select @w_op_banco_e = @w_op_banco_A
               goto ERROR
            end            


      while @@trancount > 0 
      COMMIT TRAN     ---Fin de la transaccion  
      goto SIGUIENTE  -- Continua Leyendo la Siguiente Operacion 



   ERROR:
   while @@trancount > 0 
         rollback
   
   exec sp_errorlog
        @i_fecha       = @i_fecha_proceso,
        @i_error       = @w_error,
        @i_usuario     = @s_user,
        @i_tran        = 7060, 
        @i_tran_name   = @w_sp_name,
        @i_rollback    = 'S',  
        @i_cuenta      =  @w_op_banco_e,
        @i_descripcion = 'DESEMBOLSO MASIVO DOCUMENTOS DESCONTADOS'
  
   while @@trancount > 0 
   rollback


   SIGUIENTE:
   fetch cursor_desembolso
   into  @w_op_operacion_A,  @w_op_banco_A,   @w_op_tramite_A, @w_op_fecha_ini_A

end  -- FIN CURSOR  

close cursor_desembolso 
deallocate cursor_desembolso



return 0



go

