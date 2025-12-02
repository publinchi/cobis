/***********************************************************************/
/*    Archivo:                   acciones.sp                           */
/*    Stored procedure:          sp_acciones                           */
/*    Base de datos:             cob_cartera                           */
/*    Producto:                  Cartera                               */
/*    Fecha de escritura:        20/Jun/99                             */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de    */
/*    'COBISCORP'.                                                     */
/*    Su uso no  autorizado  queda  expresamente prohibido asi como    */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus    */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la    */
/*    Presidencia Ejecutiva de COBISCORP o su representante.           */
/***********************************************************************/
/*                             PROPOSITO                               */
/*    Este programa permite crear,  editar  y  eliminar acciones de    */
/*    a una obligacion.                                                */
/***********************************************************************/
/*                             MODIFICACIONES                          */
/*    FECHA          AUTOR                   RAZON                     */
/*    04/Jun/99      Isaac Parra             Emisisn inicial.          */
/*    01/Jun/2022    Guisela Fernandez       Se comenta prints          */
/***********************************************************************/
use cob_cartera
go

if object_id('sp_acciones') is not null
   drop proc sp_acciones
go
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR000353 partiendo de la verion 2
create proc sp_acciones
@t_trn             int          = NULL,
@t_debug           char(1)      = 'N',
@t_file            varchar(24)  = NULL,
@t_from            descripcion  = NULL,
@s_user            login        = null,
@s_sesn            int          = null,
@s_date            datetime     = null,              
@s_term            varchar(30)  = null,
@s_org             char(1)      = null,
@s_ofi             smallint     = null,    
@i_operacion       char(1),
@i_banco           cuenta       = NULL,
@i_secuencial      int          = NULL,
@i_div_ini         int          = NULL,
@i_div_fin         int          = NULL,
@i_rubro           catalogo     = NULL,
@i_valor           money        = NULL,
@i_porcentaje      money        = NULL,
@i_divf_ini        int          = NULL,
@i_divf_fin        int          = NULL,
@i_rubrof          catalogo     = NULL,
@i_desde_cre       char(1)      = 'N',
@i_consulta        char(1)      = NULL,
@i_actualizacion   char(1)      = 'N',
@i_crea_ext        char(1)      = null,
@o_msg_msv         varchar(255) = null out
as

declare 
@w_return            int,
@w_sp_name           varchar(64),
@w_error             int,
@w_operacionca       int,
@w_secuencial        int,
@w_op_pasiva         int,
@w_continuar         char(1),
@w_tipo              char(1),
@w_opt_periodo_int   int,
@w_opt_periodo_cap   int,
@w_ac_operacion      int,     
@w_ac_div_ini        int,    
@w_ac_div_fin        int,    
@w_ac_rubro          catalogo,
@w_ac_valor          money,
@w_ac_porcentaje     float,
@w_ac_divf_ini       int,  
@w_ac_divf_fin       int,
@w_ac_rubrof         catalogo,
@w_ac_secuencial     int


select 
@w_sp_name   = 'sp_acciones',
@w_continuar = 'S'    

if @t_trn <> 7212 
begin        
   select @w_error = 901000
   goto ERROR
end

select 
@w_operacionca     = opt_operacion,
@w_tipo            = opt_tipo,
@w_opt_periodo_int = opt_periodo_cap,
@w_opt_periodo_cap = opt_periodo_int
from ca_operacion_tmp 
where opt_banco = @i_banco


if @i_operacion  = 'Q'
begin
   if exists(select 1 from ca_acciones where ac_operacion = @w_operacionca)
      select 'S'
   else 
      select 'N'

   return 0
end


/*OPCION DE BUSQUEDA DE UNA OPERACION*/

if @i_operacion = 'S'
begin
   if @i_actualizacion = 'N'
   begin
      set rowcount 20
      
      select @w_secuencial = ISNULL(@i_secuencial, 0)
      
      select 
      'Div_inicial'   = act_div_ini,
      'Div_final'     = act_div_fin,
      'Rubro origen'  = act_rubro,
      'Valor'         = act_valor,
      'Porcentaje(%)' = act_porcentaje,
      'Div_desde'     = act_divf_ini,    
      'Div_hasta'     = act_divf_fin,
      'Rubro destino' = act_rubrof,
      'Secuencial'    = act_secuencial
      from ca_acciones_tmp 
      where act_operacion  = @w_operacionca 
      and   act_secuencial > @w_secuencial
      
      set rowcount 0        
   end
   else
   begin
      set rowcount 20
      
      select @w_secuencial = isnull(@i_secuencial, 0)
      
      select 
      'Div_inicial'   = ac_div_ini,
      'Div_final'     = ac_div_fin,
      'Rubro origen'  = ac_rubro,
      'Valor'         = ac_valor,
      'Porcentaje(%)' = ac_porcentaje,
      'Div_desde'     = ac_divf_ini,    
      'Div_hasta'     = ac_divf_fin,
      'Rubro destino' = ac_rubrof,
      'Secuencial'    = ac_secuencial
      from ca_acciones
      where ac_operacion  = @w_operacionca 
      and   ac_secuencial > @w_secuencial
      
      set rowcount 0
   end
end


/*OPCION DE ELIMACION DE REGISTRO*/

if @i_operacion = 'D'  begin

   /* Valores para transaccion de servicio Acciones*/
   select 
   @w_ac_operacion  = act_operacion,
   @w_ac_div_ini    = act_div_ini,
   @w_ac_div_fin    = act_div_fin,  
   @w_ac_rubro      = act_rubro,
   @w_ac_valor      = act_valor,
   @w_ac_porcentaje = act_porcentaje,
   @w_ac_divf_ini   = act_divf_ini,
   @w_ac_divf_fin   = act_divf_fin, 
   @w_ac_rubrof     = act_rubrof, 
   @w_ac_secuencial = act_secuencial                          
   from cob_cartera..ca_acciones_tmp
   where act_secuencial = @i_secuencial        
   and   act_operacion  = @w_operacionca

   delete ca_acciones_tmp 
   where act_secuencial = @i_secuencial
   and   act_operacion  = @w_operacionca
            
   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end

     ---Transaccion de servicio - Inserción de Acciones
   insert into cob_cartera..ca_acciones_ts (
   acs_fecha_proceso_ts,         acs_fecha_ts,           acs_usuario_ts, 
   acs_oficina_ts,               acs_terminal_ts,        acs_tipo_transaccion_ts, 
   acs_origen_ts,                acs_clase_ts,           acs_operacion, 
   acs_div_ini,                  acs_div_fin,            acs_rubro, 
   acs_valor,                    acs_porcentaje,         acs_divf_ini, 
   acs_divf_fin,                 acs_rubrof,             acs_secuencial          )
   values (
   @s_date,                      getdate(),              @s_user, 
   @s_ofi,                       @s_term,                @t_trn, 
   @s_org,                       'B',                    @w_ac_operacion, 
   @w_ac_div_ini,                @w_ac_div_fin,          @w_ac_rubro, 
   @w_ac_valor,                  @w_ac_porcentaje,       @w_ac_divf_ini,
   @w_ac_divf_fin,               @w_ac_rubrof,           @w_ac_secuencial        )
   
   if @@error <> 0
   begin
      if @i_crea_ext is null
      begin
	      exec cobis..sp_cerror
	      @t_from         = @w_sp_name,
	      @i_num          = 710047
	      return 1
      end
      ELSE
      begin
        select @o_msg_msv = 'Error en Insercion en transaccion de servicio ' + @w_sp_name
      	return 710047
      end
   end             


   /* SI LA OP.ACTIVA ESTA ASOCIADA A UNA O VARIAS PASIVAS*/
   /*INSERTAR REGISTROS EN LAS PASIVAS*/
   if @w_tipo = 'C'
   begin
      declare seleccion_pasiva cursor for
      select rpt_pasiva 
      from ca_relacion_ptmo_tmp
      where rpt_activa = @w_operacionca
      for read only

      open seleccion_pasiva
      fetch seleccion_pasiva into
      @w_op_pasiva

      while   @@fetch_status = 0 
      begin 

         if (@@fetch_status = -1)  
         begin
		    --GFP se suprime print
            --PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
            return 710004
         end

         delete ca_acciones_tmp 
         where act_secuencial = @i_secuencial        
         and   act_operacion  = @w_op_pasiva

         /* Valores para transaccion de servicio Acciones*/
         select 
         @w_ac_operacion  = ac_operacion,
         @w_ac_div_ini    = ac_div_ini,
         @w_ac_div_fin    = ac_div_fin,  
         @w_ac_rubro      = ac_rubro,
         @w_ac_valor      = ac_valor,
         @w_ac_porcentaje = ac_porcentaje,
         @w_ac_divf_ini   = ac_divf_ini,
         @w_ac_divf_fin   = ac_divf_fin, 
         @w_ac_rubrof     = ac_rubrof, 
         @w_ac_secuencial = ac_secuencial                          
         from cob_cartera..ca_acciones
         where ac_secuencial = @i_secuencial        
         and   ac_operacion  = @w_op_pasiva
       
         delete ca_acciones
         where ac_secuencial = @i_secuencial        
         and   ac_operacion  = @w_op_pasiva

         ---Transaccion de servicio - Inserción de Acciones         
         insert into cob_cartera..ca_acciones_ts (
         acs_fecha_proceso_ts,         acs_fecha_ts,              acs_usuario_ts, 
         acs_oficina_ts,               acs_terminal_ts,           acs_tipo_transaccion_ts, 
         acs_origen_ts,                acs_clase_ts,              acs_operacion, 
         acs_div_ini,                  acs_div_fin,               acs_rubro,
         acs_valor,                    acs_porcentaje,            acs_divf_ini, 
         acs_divf_fin,                 acs_rubrof,                acs_secuencial          )
         values(
         @s_date,                      getdate(),                 @s_user,
         @s_ofi,                       @s_term,                   @t_trn,
         @s_org,                       'B',                       @w_ac_operacion,
         @w_ac_div_ini,                @w_ac_div_fin,             @w_ac_rubro,
         @w_ac_valor,                  @w_ac_porcentaje,          @w_ac_divf_ini,
         @w_ac_divf_fin,               @w_ac_rubrof,              @w_ac_secuencial        )
         
         if @@error <> 0
         begin
            if @i_crea_ext is null
            begin
	            exec cobis..sp_cerror
	            @t_from         = @w_sp_name,
	            @i_num          = 710047
	            return 1
            end
            ELSE
            begin
               select @o_msg_msv = 'Error en Insercion en transaccion de servicio ' + @w_sp_name
               return 710047
            end
         end             

         update ca_operacion
         set op_opcion_cap = 'N'
         where op_operacion = @w_op_pasiva


         fetch seleccion_pasiva into
         @w_op_pasiva 
      end
      close seleccion_pasiva
      deallocate seleccion_pasiva
   end
end


/*OPCION DE ELIMACION TOTAL DE REGISTROS POR CAMBIO DE TABLA DE AMORTIZACION*/

if @i_operacion = 'X'  begin

   delete ca_acciones_tmp 
   where act_operacion  = @w_operacionca
            
   /* SI LA OP.ACTIVA ESTA ASOCIADA A UNA O VARIAS PASIVAS*/
   /*INSERTAR REGISTROS EN LAS PASIVAS*/
   if @w_tipo = 'C'
   begin
      declare seleccion_pasiva cursor for
      select rpt_pasiva 
      from ca_relacion_ptmo_tmp
      where rpt_activa = @w_operacionca
      for read only

      open seleccion_pasiva
      fetch seleccion_pasiva into
      @w_op_pasiva

      while   @@fetch_status = 0 
      begin 

         if (@@fetch_status = -1)  
         begin
		    --GFP se suprime print
            --PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
            return 710004
         end

         delete ca_acciones_tmp 
         where act_operacion  = @w_op_pasiva


         delete ca_acciones
         where ac_operacion  = @w_op_pasiva


         update ca_operacion
         set op_opcion_cap = 'N'
         where op_operacion = @w_op_pasiva


         fetch seleccion_pasiva into
         @w_op_pasiva 
      end
      close seleccion_pasiva
      deallocate seleccion_pasiva
   end
end


/*OPCION DE ACTUALIZACION DE REGISTRO*/

if @i_operacion = 'U'  
begin
   if not exists(
   select 1 from ca_acciones_tmp
   where act_operacion   = @w_operacionca
   and   act_secuencial  = @i_secuencial )
   begin
      select @w_error = 710134
      goto ERROR
   end
   else  
   begin
      /* VALIDAR QUE LOS DIVIDENDOS DESTINO DE LA CAPITALIZACION NO ESTEN CANCELADOS*/
      if exists (
      select 1 from ca_dividendo_tmp
      where dit_operacion = @w_operacionca
      and   dit_dividendo between @i_divf_ini and @i_divf_fin
      and   dit_estado    = 3                                )
      begin
         select @w_error = 710413
         goto ERROR
      end

      /* VALIDAR QUE LOS DIVIDENDOS ORIGEN DE LA CAPITALIZACION NO ESTEN CANCELADOS*/
      if exists (
      select 1 from ca_dividendo_tmp
      where dit_operacion = @w_operacionca
      and   dit_dividendo between @i_div_ini and @i_div_fin
      and   dit_estado    = 3                                )
      begin
         select @w_error = 710412
         goto ERROR
      end

      /* VALIDAR QUE LOS DIVIDENDOS DESTINO DE LA CAPITALIZACION NO TENGAN GRACIA DE CAPITAL*/      
      if exists (
      select 1 from   ca_dividendo_tmp
      where dit_operacion  = @w_operacionca
      and   dit_dividendo  between @i_divf_ini and @i_divf_fin
      and   dit_de_capital = 'N'                                )
      begin
         select @w_error = 710411
         goto ERROR
      end

      update ca_acciones_tmp set
      act_div_ini    = @i_div_ini,
      act_div_fin    = @i_div_fin,
      act_rubro      = @i_rubro,
      act_valor      = @i_valor,
      act_porcentaje = @i_porcentaje,
      act_divf_ini   = @i_divf_ini,
      act_divf_fin   = @i_divf_fin,
      act_rubrof     = @i_rubrof
      where act_secuencial = @i_secuencial        
      and   act_operacion  = @w_operacionca

      if @@error <> 0 
      begin
         select  @w_error = 710002
         goto ERROR
      end
   end


   /* SI LA OP.ACTIVA ESTA ASOCIADA A UNA O VARIAS PASIVAS*/
   /* INSERTAR REGISTROS EN LAS PASIVAS   */
   if @w_tipo = 'C'
   begin
      declare seleccion_pasiva cursor for
      select rpt_pasiva 
      from ca_relacion_ptmo_tmp
      where rpt_activa = @w_operacionca
      for read only

      open seleccion_pasiva
      
      fetch seleccion_pasiva into @w_op_pasiva

      while @@fetch_status = 0
      begin 

         if (@@fetch_status = -1)  
         begin
            --GFP se suprime print
			--PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
            return 710004
         end

         update ca_acciones_tmp set
         act_div_ini    = @i_div_ini,
         act_div_fin    = @i_div_fin,
         act_rubro      = @i_rubro,
         act_valor      = @i_valor,
         act_porcentaje = @i_porcentaje,
         act_divf_ini   = @i_divf_ini,
         act_divf_fin   = @i_divf_fin,
         act_rubrof     = @i_rubrof
         where act_secuencial = @i_secuencial        
         and   act_operacion  = @w_op_pasiva

         if @@error <> 0 
         begin
            select @w_error = 710002
            goto ERROR
         end

         update ca_operacion
         set op_opcion_cap = 'S'
         where op_operacion = @w_op_pasiva

         fetch seleccion_pasiva into @w_op_pasiva
      end
      close seleccion_pasiva
      deallocate seleccion_pasiva
   end
end


/*OPERACION DE INSERCION*/
if @i_operacion = 'I'  
begin
   /* VALIDAR QUE LOS DIVIDENDOS ORIGEN DE LA CAPITALIZACION NO ESTEN CANCELADOS*/
   if exists (
   select 1 from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and   dit_dividendo between @i_div_ini and @i_div_fin
   and   dit_estado    = 3                                )
   begin
     select @w_error = 710412
     goto ERROR
   end

   /* VALIDAR QUE LOS DIVIDENDOS DESTINO DE LA CAPITALIZACION NO ESTEN CANCELADOS*/
   if exists (
   select 1 from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and   dit_dividendo between @i_divf_ini and @i_divf_fin
   and   dit_estado    = 3                                )
   begin
      select @w_error = 710413
      goto ERROR
   end

   /* VALIDAR COBRO DE INTERESES EN LOS DIVIDENDOS ORIGEN */
   if exists (
   select 1 from ca_amortizacion_tmp
   where amt_operacion = @w_operacionca
   and   amt_dividendo between @i_div_ini and @i_div_fin
   and   amt_concepto  in ('INT', 'INTANT')
   and   amt_cuota     = 0                                )
   begin
      select @w_error = 710411
      goto ERROR
   end

   /* VALIDAR QUE LOS DIVIDENDOS DESTINO DE LA CAPITALIZACION NO TENGAN GRACIA DE CAPITAL*/
   if exists (
   select 1 from ca_amortizacion_tmp
   where amt_operacion = @w_operacionca
   and   amt_dividendo between @i_divf_ini and @i_divf_fin
   and   amt_concepto  = 'CAP'
   and   amt_cuota     = 0                                )
   begin
      select @w_error = 710411
      goto ERROR
   end


   if exists(
   select 1 from ca_acciones_tmp
   where act_operacion = @w_operacionca
   and   act_rubro     = @i_rubro
   and   act_div_ini   = @i_div_ini
   and   act_div_fin   = @i_div_fin
   and   act_divf_ini  = @i_divf_ini
   and   act_divf_fin  = @i_divf_fin
   and   act_rubrof    = @i_rubrof      )
   begin
      select @w_error = 710135
      goto ERROR
   end
   else 
   begin
      if @w_continuar = 'S'
      begin
         select @w_secuencial = 0

         exec @w_secuencial = sp_gen_sec
         @i_operacion  = @w_operacionca
     
         insert ca_acciones_tmp 
         values (
         @w_operacionca,      @i_div_ini,       @i_div_fin, 
         @i_rubro,            @i_valor,         @i_porcentaje, 
         @i_divf_ini,         @i_divf_fin,      @i_rubrof,
         @w_secuencial)

         if @@error <> 0 
         begin
            select @w_error = 710001
            goto ERROR
         end
      end
      else
         return 1


      /* SI LA OP.ACTIVA ESTA ASOCIADA A UNA O VARIAS PASIVAS*/
      /*INSERTAR REGISTROS EN LAS PASIVAS*/
      if @w_tipo = 'C'
      begin
         declare seleccion_pasiva cursor for
         select rpt_pasiva 
         from ca_relacion_ptmo_tmp
         where rpt_activa = @w_operacionca
         for read only

         open seleccion_pasiva
         fetch seleccion_pasiva into 
         @w_op_pasiva 

         while @@fetch_status = 0 
         begin 

            if @@fetch_status = -1
            begin
               --GFP se suprime print
			   --PRINT 'acciones.sp  error en lectura del cursor seleccion_pasiva'
               return 710004
            end

            insert ca_acciones_tmp 
            values (
            @w_op_pasiva,         @i_div_ini,          @i_div_fin, 
            @i_rubro,             @i_valor,            @i_porcentaje, 
            @i_divf_ini,          @i_divf_fin,         @i_rubrof,
            @w_secuencial)

            if @@error <> 0 
            begin
               select @w_error = 710001
               goto ERROR
            end

            update ca_operacion
            set op_opcion_cap = 'S'
            where op_operacion = @w_op_pasiva


            fetch seleccion_pasiva into
            @w_op_pasiva
         end
         close seleccion_pasiva
         deallocate seleccion_pasiva
      end
   end
end



if exists(select 1 from ca_acciones_tmp where act_operacion = @w_operacionca)
   update ca_operacion_tmp 
   set opt_opcion_cap = 'S'
   where opt_operacion = @w_operacionca
else
   update ca_operacion_tmp 
   set opt_opcion_cap = 'N'
   where opt_operacion = @w_operacionca
   
return 0


ERROR:
if @i_crea_ext is null
begin
	exec @w_return = cobis..sp_cerror
	@t_debug  = @t_debug,
	@t_file   = @t_file,
	@t_from   = @w_sp_name,
	@i_num    = @w_error
end    
else
select @o_msg_msv = 'Error en transaccion de servicio ' + @w_sp_name   

return @w_error

go
