/************************************************************************/
/*   Archivo:              abmacabe.sp                                  */
/*   Stored procedure:     sp_abonos_masivos_cabecera                   */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Julio Cesar Quintero                         */
/*   Fecha de escritura:   Marzo 26-2003                                */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Carga Cabecera Plano (Pagos Masivos Convenios o Generales          */
/*      Valida los datos de control (Oficina, Monto, Secuencial)        */
/*      LAS OPERACIONES MANEJADAS SON:                                  */
/*                                                                      */
/*      'V'     Valida Total Registros, Secuencial y Monto Total        */
/*      'I'     Inserta Primer Registro en tabla de cabecera antes      */
/*              cargar el plano a la grilla.                            */
/*                                                                      */
/*   MODIFICACIONES                                                     */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_abonos_masivos_cabecera')
   drop proc sp_abonos_masivos_cabecera
go

create proc sp_abonos_masivos_cabecera
   @s_ssn               int         = null,
   
   @s_date              smalldatetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint     = null,
   @t_debug             char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_fecha_proceso     smalldatetime    = null,
   @i_fecha_archivo     smalldatetime    = null,
   @i_monto_total       money       = null,
   @i_monto_calculado   money       = null,
   @i_secuencial        int         = null,
   @i_total_registros   int         = null,
   @i_total_reg_calcul  int         = null,
   @i_lote              int         = null,
   @i_opcion            char(1)     = null,
   @i_archivo           varchar(100)= null,
   @o_reg_cargados      int         = null out,
   @o_reg_errores       int         = null out

as
declare
   @w_sp_name                      varchar(32),
   @w_return                       int,
   @w_error                        int,
   @w_oficina                      int,
   @w_fecha_archivo                smalldatetime,
   @w_monto_total                  money,
   @w_secuencial                   int,
   @w_estado                       char(1),
   @w_lote                         int,
   @w_reg_cargados                 int,
   @w_reg_errores                  int

-- CAPTURA NOMBRE DE STORED PROCEDURE
select   @w_sp_name = 'sp_abonos_masivos_cabecera'

---  VALIDACION DATOS DE CABECERA
if @i_operacion = 'V' begin
   -- ESTADO INGRESADO 
   select @w_estado = 'I'
   
   -- FECHA DEL SISTEMA 
   select @i_fecha_proceso = convert(char(10),getdate(),103)
   from   cobis..ba_fecha_proceso 
   
   -- VALIDACION SECUENCIAL ARCHIVO
   select @w_secuencial = mc_secuencial
   from   ca_abonos_masivos_cabecera  
   where  mc_secuencial = @i_secuencial
   --and    mc_estado = 'P'
   
   if @@rowcount > 0 begin -- YA EXISTE UN ARCHIVO CARGADO CON ESE SECUENCIAL
      select @w_error = 710470
      goto ERROR
   end
   
   -- VALIDACION MONTO TOTAL
   if @i_monto_calculado <> @i_monto_total begin
      select @w_error = 710439
      goto ERROR
   end
   
   -- VALIDACION TOTAL REGISTROS 
   if @i_total_registros <> @i_total_reg_calcul begin
      select @w_error = 710440
      goto ERROR
   end
end

if @i_operacion = 'I' begin

   if exists (select 1 from ca_abonos_masivos_cabecera
              where mc_archivo = @i_archivo
             )
   begin
      select @w_error = 724518
      goto ERROR
   end

   select @w_estado = mc_estado
   from   ca_abonos_masivos_cabecera
   where  (mc_secuencial = @i_secuencial or mc_lote = @i_lote) -- DEFECTO 6967 CONTROL DE LOTES REPETIDOS SIN APLICAR
   and    mc_estado = 'I'
   
   if @@rowcount > 0 begin
      ---Eliminar los registros de rechazos de la cabecera en estado I
      delete from ca_abonos_masivos_cabecera
      where  (mc_secuencial = @i_secuencial or mc_lote = @i_lote)
      and    mc_estado = 'I'
      
      ---Eliminar los registros de la tabla ppal. en estado I del lote o secuencia
      delete from ca_abonos_masivos_generales
      where  mg_estado = 'I'
      and    mg_lote = @i_lote
   end
   
   -- INSERCION DE REGISTRO DE CABECERA 
   insert into ca_abonos_masivos_cabecera
   (mc_total_registros,    mc_fecha_archivo,    mc_monto_total,
   mc_secuencial,          mc_estado,           mc_lote, mc_errores, mc_archivo)
   values
   (@i_total_registros,    @i_fecha_archivo,    @i_monto_total,
   @i_secuencial,         'I',                  @i_lote, 0, @i_archivo)
   
   if @@error != 0 begin
      select @w_error = 710441
      goto ERROR
   end
end

if @i_operacion = 'D' begin
      delete from ca_abonos_masivos_cabecera
      where mc_archivo = @i_archivo
end

if @i_operacion = 'R' begin
   if not exists (select 1
                  from   ca_abonos_masivos_generales
                  where  mg_lote   = @i_lote
                  and    mg_terminal <> 'PIT')
   begin
      delete from ca_abonos_masivos_cabecera
      where  mc_secuencial = @i_secuencial
      and    mc_lote       = @i_lote
   end
   ELSE begin
      select @w_reg_cargados = count(1)
      from   ca_abonos_masivos_generales
      where  mg_lote = @i_lote
      and    mg_terminal <> 'PIT'
      and    mg_codigo_error = 0
     
      select @w_reg_errores = count(1)
      from   ca_abonos_masivos_generales
      where  mg_lote   = @i_lote
      and    mg_terminal <> 'PIT'
      and    mg_codigo_error > 0      
      
      if @w_reg_errores > 0 begin
         update ca_abonos_masivos_cabecera
         set    mc_errores = @w_reg_errores
         where  mc_secuencial = @i_secuencial
         and    mc_lote       = @i_lote
      end
      
      select @o_reg_cargados = @w_reg_cargados
      select @o_reg_errores  = @w_reg_errores
      
      select @o_reg_cargados
      select @o_reg_errores
   end
end

--MARCAR EL LOTE COMO ANULADO
if @i_operacion = 'E' begin
   if @i_opcion = '0' begin
      if exists (select 1
                 from   ca_abonos_masivos_cabecera
                 where  mc_lote   = @i_lote
                 and    mc_estado = 'E')
      begin
         select @w_error = 710520
         goto ERROR
      end
      
      if not exists (select 1
                     from   ca_abonos_masivos_generales
                     where  mg_lote   = @i_lote)
      begin
         select @w_error = 710518
         goto ERROR
      end
      
      if exists (select 1
                 from   ca_abonos_masivos_generales,ca_abono
                 where  ab_operacion = mg_operacion
                 and    ab_secuencial_ing = mg_secuencial_ing
                 and    ab_estado  = 'A'
                 and    mg_lote   = @i_lote )
      begin
         select @w_error = 710519
         goto ERROR
      end
      
      update  ca_abonos_masivos_generales
      set mg_estado = 'E'
      where mg_lote   = @i_lote
      
      update  ca_abonos_masivos_cabecera
      set mc_estado = 'E'
      where mc_lote   = @i_lote
      
      if exists (select 1 from ca_abonos_masivos_generales,ca_abono
                 where ab_operacion = mg_operacion 
                 and   ab_secuencial_ing = mg_secuencial_ing
                 and   ab_estado  = 'ING'
                 and   mg_lote   = @i_lote)
      begin
         update ca_abono
         set    ab_estado = 'ANU'
         from   ca_abonos_masivos_generales,ca_abono
         where  ab_operacion = mg_operacion 
         and    ab_secuencial_ing = mg_secuencial_ing
         and    ab_estado  = 'ING'
      end
   end
   ELSE begin
      if @i_opcion = '1' begin
         --CONVENIOS LIBRANZAS PARA EL BAC
         if not exists (select 1 from  ca_abono_masivo
                        where  abm_lote   = @i_lote)
         begin
            select @w_error = 710518
            goto ERROR
         end
         
         if exists (select 1 from ca_abono_masivo,ca_abono
                    where ab_operacion = abm_operacion
                    and   ab_secuencial_ing = abm_secuencial_ing
                    and   ab_estado  = 'A'
                    and   abm_lote   = @i_lote )
         begin
            select @w_error = 710519
            goto ERROR
         end
         
         update ca_abono_masivo 
         set    abm_estado = 'E'
         where  abm_lote   = @i_lote
         
         --CABECERA DE LIBRANZAS
         update ca_abonos_masivos_his
         set    amh_estado = 'E'
         where  amh_lote  = @i_lote 
         
         if exists(select 1 from ca_abono_masivo,ca_abono
                   where ab_operacion = abm_operacion 
                   and   ab_secuencial_ing = abm_secuencial_ing
                   and   ab_estado  = 'A'
                   and   abm_lote   = @i_lote )
         begin
            update ca_abono
            set    ab_estado = 'ANU'
            from   ca_abono_masivo,ca_abono
            where  ab_operacion = abm_operacion 
            and    ab_secuencial_ing = abm_secuencial_ing
            and    ab_estado  = 'ING'
         end
      end
   end
end

return 0


ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error
   return @w_error  
go