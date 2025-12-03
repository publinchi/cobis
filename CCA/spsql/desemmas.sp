/************************************************************************/
/*   Archivo:              desemmas.sp                                  */
/*   Stored procedure:     sp_desembolsos_masivos                       */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Julio Cesar Quintero                         */
/*   Fecha de escritura:   Enero 08 de 2002                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Este programa desembolsa simultaneamente las operaciones pasivas   */
/*   y activas en forma automatica teniendo en cuenta las lineas de     */
/*   credito incluidas en la tabla de correspondencias y procesos.      */
/*                                                                      */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*     FECHA        AUTOR                    RAZON                      */
/*   03/09/2004   Julio C Quintero   Ajuste de Errores 701121, 708224,  */
/*                                 708227, 701049                       */
/*                                                                      */
/*      OCT-2005       Elcira Pelaez  Cambios para el BAC               */
/*      ABR-2006        Elcira Pelaez          NR.  296                 */
/*      ABR-2021       Johan Hernandez    Corrección instaladores       */
/************************************************************************/



use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desembolsos_masivos')
   drop proc sp_desembolsos_masivos
go

create proc sp_desembolsos_masivos (
   @s_user           login        = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime,
   @s_ofi            smallint     = null,
   @i_fecha_proceso  datetime
)
as
declare
   @w_sp_name                 varchar(30),
   @w_error                   int,
   @w_op_operacion_p          int,
   @w_op_operacion_A          int,
   @w_dm_operacion_a          int,
   @w_dm_operacion_p          int,
   @w_op_tramite_A            int,
   @w_op_tramite_p            int,
   @s_ssn                     int,
   @s_sesn                    int,
   @w_op_estado_p             int,
   @w_tabla_credito           varchar(30),
   @w_op_toperacion_A         catalogo,
   @w_op_toperacion_p         catalogo,
   @w_op_banco_A1              cuenta,
   @w_op_banco_a              cuenta,
   @w_op_banco_e              cuenta,
   @w_op_banco_p               cuenta,
   @w_bco_cre_p               cuenta,
   @w_op_codigo_externo_A1     cuenta,
   @w_op_codigo_externo_a     cuenta,
   @w_cod_ext                 cuenta,
   @w_op_fecha_ini_A          datetime,
   @w_fecha_fin_p             datetime,
   @w_op_fecha_ini_p          datetime,
   @w_oficina_central         int,
   @w_op_margen_redescuento_A1 float,
   @w_op_margen_redescuento_a float,
   @w_op_tipo_linea_A         catalogo,
   @w_op_tipo_linea_p         catalogo,
   @w_llave_redescuento_a       cuenta,
   @w_op_monto_p              money,
   @w_op_monto_A              money,
   @w_hora                    char(8),
   @w_codigo_finagro          varchar(30),
   @w_op_estado_A             smallint,
   @w_fecha_fin_A             datetime,
   @w_activa                  char(1),
   @w_op_tipo                 char(1),
   @w_rowcount                int



/* VARIABLES INICIALES  */
/************************/
select   @w_sp_name    = 'sp_desembolsos_masivos',
         @w_activa     = 'S'



/* PARAMETRO LINEAS DE CREDITO CON DESEMBOLSOS MASIVOS  */
/********************************************************/

select @w_codigo_finagro = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FINAG'

select @w_tabla_credito = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'DMASIV' --DESEMBOLSO MASIVO 
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = 710384
--        @i_cuenta = ' '
   
   return 2101084
end



select @w_oficina_central = 9000


select @w_oficina_central = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'OFC' --OFICINA CENTRALIZADORA
and    pa_producto = 'CON'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = 710384
--        @i_cuenta = ' '
        return 2101084
end
ELSE
   select @s_ofi = @w_oficina_central




/* CURSOR DE LINEAS QUE SE PUEDEN DESEMBOLSAR MASIVAMENTE */
/**********************************************************/

declare
   cursor_desembolso cursor
   for select distinct op_operacion,   op_toperacion,       op_banco,
                       op_tramite,     op_estado,           op_fecha_ini,
                       op_fecha_fin,   op_codigo_externo,   isnull(op_margen_redescuento,0),
                       op_tipo_linea,  op_monto,	    op_tipo
       from   ca_desembolso,   ca_operacion, cob_credito..cr_corresp_sib   
       where  dm_operacion   = op_operacion
       and    op_toperacion  = codigo
       and    op_fecha_ini  <= @i_fecha_proceso
       and    op_estado      = 0      
       and    op_tipo       not in  ('R','D')
       and    tabla = @w_tabla_credito

   for read only

open cursor_desembolso

fetch cursor_desembolso
into  @w_op_operacion_A,  @w_op_toperacion_A,       @w_op_banco_A1,
      @w_op_tramite_A,    @w_op_estado_A,           @w_op_fecha_ini_A,
      @w_fecha_fin_A,     @w_op_codigo_externo_A1,   @w_op_margen_redescuento_A1,
      @w_op_tipo_linea_A, @w_op_monto_A,            @w_op_tipo

while @@fetch_status = 0 

begin
   if @@fetch_status = -1
   begin
      select @w_error = 708157
      goto  ERROR_DES
   end  


   if @w_op_tipo = 'C'    ---ACTIVAS SOLO OPERACIONES DE REDESCUENTO
   begin

      /* VALIDACIONES PARA ACTIVAS OPERACIONES DE FINAGRO */
      /****************************************************/
   
      if @w_op_tipo_linea_A =  @w_codigo_finagro
      begin

         select @w_llave_redescuento_a   = tr_llave_redes
         from   cob_credito..cr_tramite
         where  tr_tramite = @w_op_tramite_A
      
         if @w_llave_redescuento_a is null
         begin
            select @w_error = 710458
            select @w_op_banco_e = @w_op_banco_A1
            goto  ERROR 
         end

         /* BUSCA TRAMITE PASIVO */
         /************************/

         select @w_op_tramite_p = tr_tramite
         from   cob_credito..cr_tramite --(index cr_tramite_AKey3)
         where  tr_llave_redes = @w_llave_redescuento_a
         and    substring(tr_toperacion,10,1) = '2'
      
         if @@rowcount = 0 
         begin
            select @w_error = 710504
            select @w_op_banco_e = @w_op_banco_A1
            goto  ERROR
         end
      

         select @w_op_toperacion_p  = op_toperacion,
                @w_op_operacion_p   = op_operacion,
                @w_op_monto_p       = op_monto,
                @w_op_banco_p       = op_banco,
                @w_op_fecha_ini_p   = op_fecha_ini,
                @w_op_estado_p      = op_estado,
                @w_fecha_fin_p      = op_fecha_fin,
                @w_op_tipo_linea_p  = op_tipo_linea
         from   cob_cartera..ca_operacion
         where  op_tramite      = @w_op_tramite_p
      
         if @@rowcount = 0
         begin
            select @w_activa = 'N'
            select @w_error = 701049
            select @w_op_banco_e = @w_op_banco_A1
            goto  ERROR
         end
      

         /* VALIDACION DE EXISTENCIA DE REGISTRO EN ca_relacion_ptmo */
         /************************************************************/
      
         if exists (select 1 from ca_relacion_ptmo
                    where  rp_pasiva = @w_op_operacion_p)
         begin
            set rowcount 1
            select @w_op_operacion_p = rp_pasiva
            from   ca_relacion_ptmo
            where  rp_activa = @w_op_operacion_A 
            set rowcount 0
         end
         ELSE
         begin
            select @w_hora = right('00'+convert(varchar(8),datepart(hh,getdate())),2)+':'+right('00'+convert(varchar(8),datepart(mi,getdate())),2)+':'+right('00'+convert(varchar(8),datepart(mi,getdate())),2)
         
            BEGIN TRAN   --SI NO EXISTE REGISTRO SE inserta en ca_relacion_ptmo
               insert into ca_relacion_ptmo
                     (rp_activa,          rp_pasiva,            rp_lin_activa,
                      rp_lin_pasiva,      rp_fecha_ini,         rp_fecha_fin,
                      rp_porcentaje_act,  rp_porcentaje_pas,    rp_saldo_act,
                      rp_saldo_pas,       rp_fecha_grb,         rp_fecha_upd,
                      rp_usuario_grb,     rp_usuario_upd,       rp_hora_grb,
                      rp_hora_upd)
               values (@w_op_operacion_A,  @w_op_operacion_p,    @w_op_toperacion_A,
                      @w_op_toperacion_p,  @w_op_fecha_ini_A,    @w_fecha_fin_A,
                      0,                   0,                    @w_op_monto_A,
                      @w_op_monto_p,       @i_fecha_proceso,     null,
                      @s_user,             null,                 @w_hora,
                      null)
            COMMIT TRAN
         end  
      end 
      ELSE
      BEGIN

         /** VALIDACION RELACION EN CA_RELACION_PTMO PARA OPERACIONES REDESCUENTO QUE NO SON DE FINAGRO **/
         /*************************************************************************************************/

         select @w_op_operacion_p = rp_pasiva
         from   ca_relacion_ptmo
         where  rp_pasiva = @w_op_operacion_A

         if @@rowcount = 0
         begin
            select @w_error = 710486
            select @w_op_banco_e = @w_op_banco_A1
            goto  ERROR
         end
      
         select @w_op_toperacion_p  = op_toperacion,
                @w_op_monto_p       = op_monto,
                @w_op_banco_p       = op_banco,
                @w_op_fecha_ini_p   = op_fecha_ini,
                @w_op_estado_p      = op_estado,
                @w_fecha_fin_p      = op_fecha_fin,      
                @w_op_tipo_linea_p  = op_tipo_linea
         from   cob_cartera..ca_operacion
         where  op_operacion   = @w_op_operacion_p
      
         if @@rowcount = 0
         begin
            select @w_activa = 'N'
            select @w_error = 701049
            select @w_op_banco_e = @w_op_banco_A1
            goto  ERROR
         end
      
      END
   

      /*** VALIDACION TIPO DE LINEA PARA OPERACIONES DE REDESCUENTO (FINAGRO Y NO FINAGRO)  ***/
      /****************************************************************************************/

      if @w_op_tipo_linea_A <> @w_op_tipo_linea_p  
      begin
         select @w_error = 710506
         goto ERROR
      end
   

      /** EXISTE REGISTRO DE DESEMBOLSO PASIVA **/
      /******************************************/

      select @w_dm_operacion_p = dm_operacion
      from   ca_desembolso
      where  dm_operacion = @w_op_operacion_p
   
      if @@rowcount = 0
      begin
         select @w_error = 701121
         select @w_op_banco_e = @w_op_banco_p
         goto  ERROR
      end
   

      /** VALIDACION FECHA INICIAL **/
      /******************************/

      if @w_op_fecha_ini_A <> @w_op_fecha_ini_p 
      begin
         select @w_error = 708224
         select @w_op_banco_e = @w_op_banco_A1
         goto  ERROR
      end
      else
         update ca_operacion
         set    op_fecha_liq = @w_op_fecha_ini_A
         where  op_tramite   = @w_op_tramite_A
      


      /** VALIDACION FECHA FINAL **/
      /****************************/

      if @w_fecha_fin_p <> @w_fecha_fin_A
      begin
         select @w_error = 708225
         goto ERROR
      end

      if @w_op_tipo_linea_A =  @w_codigo_finagro and @w_op_codigo_externo_A1 is null
      begin
         --SACARLO DE TRAMITES
         update ca_operacion 
         set    op_codigo_externo = @w_llave_redescuento_a
         where  op_tramite = @w_op_tramite_A
  
         select @w_op_codigo_externo_A1 = @w_llave_redescuento_a
      end  
   end    ---FIN ---ACTIVAS SOLO OPERACIONES DE REDESCUENTO


   /*** LIQUIDACION SOLO OPERACIONES DE REDESCUENTO ***/
   /***************************************************/
   if @w_op_tipo = 'C'    
   begin
      BEGIN TRAN -- ATOMICIDAD POR REGISTRO
      

         /* INICIO DESEMBOLSO PASIVA */
         if @w_op_estado_p = 0
         begin  
            /** SACAR SECUENCIALES SESIONES**/
            exec @s_ssn = sp_gen_sec 
                 @i_operacion  = -1
      
            exec @s_sesn = sp_gen_sec 
                 @i_operacion  = -1
      
            
            exec @w_error = sp_liquidades
                 @s_ssn            = @s_ssn,    
                 @s_sesn           = @s_sesn,
                 @s_user           = @s_user,
                 @s_date           = @s_date,
                 @s_ofi            = @s_ofi,
                 @s_rol            = 1,
                 @s_term           = @s_term,
                 @i_banco_ficticio = @w_op_banco_p,
                 @i_banco_real     = @w_op_banco_p,
                 @i_afecta_credito = 'N',
                 @i_fecha_liq      = @w_op_fecha_ini_p
      
            if @w_error <> 0 
            begin
               select @w_op_banco_e = @w_op_banco_p
               goto ERROR
            end 
            else 
            begin  
               select @w_bco_cre_p = op_banco
               from   cob_cartera..ca_operacion
               where  op_operacion = @w_op_operacion_p
         
               update cob_credito..cr_tramite
               set    tr_numero_op       = @w_op_operacion_p,     
                      tr_numero_op_banco = @w_bco_cre_p
               where  tr_tramite = @w_op_tramite_p
         
               if @@error != 0
               begin
                  select @w_error = 2105051
                  select @w_op_banco_e = @w_bco_cre_p
                  goto ERROR
               end
            end
         end  --- FIN DESEMBOLSO PASIVA
   



         /*** INICIO DESEMBOLSO DE LA ACTIVA ***/
         /**************************************/

         if @w_op_estado_A = 0
         begin  

            select @w_dm_operacion_a = dm_operacion
            from   ca_desembolso
            where  dm_operacion = @w_op_operacion_A
   
            if @@rowcount = 0
            begin
               select @w_error = 701121
               select @w_op_banco_e = @w_op_banco_A1
               goto  ERROR
            end


            /** SACAR SECUENCIALES SESIONES  **/
            /**********************************/

            exec @s_ssn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @s_sesn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @w_error = sp_liquidades
                 @s_ssn             = @s_ssn,
                 @s_sesn            = @s_sesn,
                 @s_user            = @s_user,
                 @s_date            = @s_date,
                 @s_ofi             = @s_ofi,
                 @s_rol             = 1,
                 @s_term            = @s_term,
                 @i_banco_ficticio  = @w_op_banco_A1,
                 @i_banco_real      = @w_op_banco_A1,
                 @i_afecta_credito  = 'N',
                 @i_fecha_liq       = @w_op_fecha_ini_A
      
                 if @w_error <> 0
                 begin
                    select @w_op_banco_e = @w_op_banco_A1
                    goto ERROR
                 end
   
   
            /* NUEVOS DATOS DESPUES DEL DESEMBOLSO DE LA ACTIVA  PARA ACTUALIZAR CREDITO */
            /*****************************************************************************/

            select @w_op_banco_a    = op_banco
            from   cob_cartera..ca_operacion
            where  op_operacion    = @w_op_operacion_A
      
            update cob_credito..cr_tramite
            set    tr_numero_op       = @w_op_operacion_A,     
                   tr_numero_op_banco = @w_op_banco_a
            where  tr_tramite         = @w_op_tramite_A
      
            if @@error != 0
            begin
               select @w_error = 2105051
               select @w_op_banco_e =  @w_op_banco_a
               goto ERROR
            end
         end  -- FIN DESEMBOLSO ACTIVA 
         else 
         begin
            select @w_error = 710505
            select @w_op_banco_e =  @w_op_banco_A1
            goto ERROR
         end
   
   
      while @@trancount > 0 
      COMMIT TRAN     ---Fin de la transaccion  

      goto SIGUIENTE  -- Continua Leyendo la Siguiente Operacion 
   end 
   ELSE 
   begin

      /*** SOLO OPERACIONES ACTIVAS DIFERENTE DE REDESCUENTO ***/
      /*********************************************************/
      if @w_op_tipo = 'O' and  @w_op_estado_A <> 0---ROTATIVOS NR 296
      begin
            select @w_error = 711034
            select @w_op_banco_e =  @w_op_banco_A1
            goto ERROR
      end
      else
      begin
      BEGIN TRAN
         if @w_op_estado_A = 0
         begin  

            select @w_dm_operacion_a = dm_operacion
            from   ca_desembolso
            where  dm_operacion = @w_op_operacion_A
   
            if @@rowcount = 0
            begin
               select @w_error = 701121
               select @w_op_banco_e = @w_op_banco_A1
               goto  ERROR
            end


            /** SACAR SECUENCIALES SESIONES  **/
            exec @s_ssn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @s_sesn = sp_gen_sec
                 @i_operacion  = -1
      
            exec @w_error = sp_liquidades
                 @s_ssn             = @s_ssn,
                 @s_sesn            = @s_sesn,
                 @s_user            = @s_user,
                 @s_date            = @s_date,
                 @s_ofi             = @s_ofi,
                 @s_rol             = 1,
                 @s_term            = @s_term,
                 @i_banco_ficticio  = @w_op_banco_A1,
                 @i_banco_real      = @w_op_banco_A1,
                 @i_afecta_credito  = 'N',
                 @i_fecha_liq       = @w_op_fecha_ini_A
      
                 if @w_error <> 0
                 begin
                    select @w_op_banco_e = @w_op_banco_A1
                    goto ERROR
                 end
   
   
            -- NUEVOS DATOS DESPUES DEL DESEMBOLSO DE LA ACTIVA  PARA ACTUALIZAR CREDITO 

            select @w_op_banco_a    = op_banco
            from   cob_cartera..ca_operacion
            where  op_operacion    = @w_op_operacion_A
      
            update cob_credito..cr_tramite
            set    tr_numero_op       = @w_op_operacion_A,     
                   tr_numero_op_banco = @w_op_banco_a
            where  tr_tramite         = @w_op_tramite_A
      
            if @@error != 0
            begin
               select @w_error = 2105051
               select @w_op_banco_e =  @w_op_banco_A1
               goto ERROR
            end
         end

      while @@trancount > 0 
      COMMIT TRAN     ---Fin de la transaccion  
      goto SIGUIENTE  -- Continua Leyendo la Siguiente Operacion 
     end  
   end


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
        @i_descripcion = 'DESEMBOLSO MASIVO BATCH'
  
   while @@trancount > 0 
   rollback


   SIGUIENTE:
   fetch cursor_desembolso
   into  @w_op_operacion_A,   @w_op_toperacion_A,     @w_op_banco_A1,
         @w_op_tramite_A,     @w_op_estado_A,         @w_op_fecha_ini_A,
         @w_fecha_fin_A,      @w_op_codigo_externo_A1, @w_op_margen_redescuento_A1,
         @w_op_tipo_linea_A,  @w_op_monto_A,            @w_op_tipo

end  -- FIN CURSOR  DESEMBOLSO

close cursor_desembolso 
deallocate cursor_desembolso



return 0


   ERROR_DES:
   while @@trancount > 0 
         rollback
  
   exec sp_errorlog
        @i_fecha       = @i_fecha_proceso,
        @i_error       = @w_error,
        @i_usuario     = @s_user,
        @i_tran        = 760, 
        @i_tran_name   = @w_sp_name,
        @i_rollback    = 'S',  
        @i_cuenta      =  'TECNICO',
        @i_descripcion = 'FALLO EL FETCH DEL CURSOR desembolso'

return 0

go

