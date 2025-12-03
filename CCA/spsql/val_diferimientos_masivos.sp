/************************************************************************/
/*  Archivo:              val_diferimientos_masivos.sp                  */
/*  Stored procedure:     sp_val_diferimientos_masivos                  */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Juan Carlos Guzman                            */
/*  Fecha de escritura:   23/Nov/2021                                   */
/************************************************************************/
/*             IMPORTANTE                                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCorp.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCorp para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Realizar validaciones a los registros de diferimientos masivos      */
/*  que estan en la tabla temporal y efectuar el procesamiento de       */
/*  ellos en tablas definitivas.                                        */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA          AUTOR       RAZON                                    */
/*  23/Nov/2021    JGU         Emision Inicial                          */
/************************************************************************/

use cob_cartera
go

set nocount on
go

if exists(select 1 from sysobjects where name = 'sp_val_diferimientos_masivos' and type = 'P')
   drop proc sp_val_diferimientos_masivos 
go

create proc sp_val_diferimientos_masivos
/*(
   
)*/

as
declare @w_banco           cuenta,
        @w_dividendo       int,
		@w_fecha_ven       datetime,
		@w_cuota_cap       money,
		@w_banco_ant       cuenta,
		@w_dividendo_ant   int,
		@w_primer_div      char(1),
		@w_cons_div        tinyint,
		@w_fecha_ven_ant   datetime,
		@w_msg_error       varchar(1000),
		@w_error_ini       char(1),
		@w_fecha1          date,
		@w_fecha2          date,
		@w_cuota_cap1      money,
		@w_cuota_cap2      money,
		@w_num_operacion   int,
		@w_num_ope_ant     int,
		@w_err1            tinyint,
		@w_err2            tinyint,
		@w_err3            tinyint,
		@w_return          int,
		@w_count           tinyint,
		@w_paso_temp       char(1),
		@w_rows_cursor     int,
		@w_plazo_rest      int,
		@w_fecha_ini       smalldatetime,
						   
        /*PROCESAMIENTO*/
		@w_div_proc        smallint,
		@w_fecha_ven_proc  datetime,
		@w_str_div         varchar(300),
		@w_str_gen         varchar(3000),
		@w_equival         smallint,
		@w_other_val_proc  money,
		@w_valor_proc      money,
		@w_rub_cap_final   money,
		@w_str_rubs        varchar(100),
		@w_min_div         smallint,
		@w_cont_rubs       smallint,
		@w_cuo_cap_ant     money,
		@w_tipo_rub_proc   char(1),
		@w_saldo_proc      money,
		@w_count_divs      smallint,
		@w_cant_divs       smallint,
		@w_pos_amp         smallint,
		@w_count_str       smallint,
		@w_value_str       varchar(300),

		/*PARA sp_decodificador*/
		@w_str1            varchar(255) = '',
        @w_str2            varchar(255) = '',
        @w_str3            varchar(255) = '',
        @w_str4            varchar(255) = '',
        @w_str5            varchar(255) = '',
        @w_str6            varchar(255) = '',
        @w_str7            varchar(255) = '',
        @w_str8            varchar(255) = '',
        @w_str9            varchar(255) = '',
        @w_str10           varchar(255) = '',

		/*PARA BCP OUT*/
		@w_tipo_bcp       varchar(10),
        @w_separador      varchar(1),
		@w_path_destino   varchar(500),
		@w_sql            varchar(255)


select @w_error_ini     = 'N',
       @w_paso_temp     = 'N',
	   @w_primer_div    = 'S',
       @w_banco_ant     = 0,
	   @w_dividendo_ant = 0,
	   @w_cons_div      = 0,
	   @w_fecha_ven_ant = '',
	   @w_count         = 1,
	   @w_err1          = 0,
	   @w_err2          = 0,
	   @w_err3          = 0,

	   @w_div_proc      = 0,
	   @w_cont_rubs     = 0,
	   @w_count_divs    = 1,

	   @w_tipo_bcp     = 'out',
       @w_path_destino = 'C:\COBIS\Vbatch\cartera\listados\ca_log_carga_manual.txt',
       @w_separador    = '|',
	   @w_sql		   = 'cob_cartera..ca_log_carga_manual'


--Truncate tabla de errores
truncate table ca_log_carga_manual

declare cur_difer_masivos cursor for
select 
   atm_banco,     atm_dividendo, 
   atm_fecha_ven, atm_cuota_capital
from cob_cartera..ca_archivo_tabla_manual
order by atm_banco, atm_dividendo

open cur_difer_masivos

fetch next from cur_difer_masivos into
   @w_banco,      @w_dividendo,
   @w_fecha_ven,  @w_cuota_cap


if @@FETCH_STATUS = -1
begin
	-- TODO: Control de errores
	print 'Error 1'
end

select @w_banco_ant   = @w_banco,
       @w_rows_cursor = @@CURSOR_ROWS

while @@FETCH_STATUS = 0
begin

   select @w_num_operacion = 0,
          @w_fecha1 = '',
		  @w_fecha2 = '',
		  @w_cuota_cap2 = 0

   select @w_num_operacion = op_operacion 
   from ca_operacion 
   where op_banco = @w_banco

   if @w_banco != @w_banco_ant
   begin
      select @w_primer_div = 'S',
	         @w_err1 = 0,
	         @w_err2 = 0,
	         @w_err3 = 0

	  if not exists(select 1 
	                from ca_log_carga_manual 
					where lcm_banco = @w_banco_ant)
	  begin
	     select @w_paso_temp = 'S'
	     print 'Pasa a temp: ' + convert(varchar(15), @w_banco_ant)

		 goto PASO_TEMP
	  end
   end

   CONTINUACION:
   print 'Continua: ' + convert(varchar(15), @w_banco_ant) + ' y ' + convert(varchar(15), @w_banco) + ' y ' + convert(varchar(15), @w_count)
   -- Validaci�n 1. campo @w_banco
   if not exists(select 1 from cob_cartera..ca_operacion
	             where op_banco = @w_banco
				   and op_estado not in (0, 99)
   )
   begin
      if @w_err1 = 0
	  begin
	     print 'Error @w_banco prestamo: ' + @w_banco
	     select @w_error_ini = 'S',
	            @w_msg_error = 'Prestamo no existe o no se encuentra en un estado permitido para el procesamiento',
				@w_err1 = 1

	     goto ERR_VALIDACION_INI
	  end
   end

   -- Validación 2. campo @w_dividendo  Primer Dividendo
   if @w_primer_div = 'S'
   begin

      select @w_cons_div = di_estado,
	         @w_fecha_ini = di_fecha_ini
      from ca_dividendo
      where di_dividendo = @w_dividendo
        and di_operacion = @w_num_operacion

      if @w_cons_div != 0
	  begin
	     print 'Error @w_dividendo: ' + convert(varchar(5),@w_dividendo)
	     select @w_error_ini = 'S',
	            @w_msg_error = 'Primer dividendo a modificar no corresponde a estado NO VIGENTE'

	     goto ERR_VALIDACION_INI
	  end
   end
   else -- Validaci�n 3. campo @w_dividendo Dividendos consecutivos
   begin
      if (@w_dividendo_ant + 1) != @w_dividendo
	  begin
	     if @w_err2 = 0
	     begin
		    print 'Error @w_dividendo: ' + convert(varchar(5),@w_dividendo)
	        select @w_error_ini = 'S',
	               @w_msg_error = 'Dividendos del prestamo no son consecutivos',
				   @w_err2 = 1

	        goto ERR_VALIDACION_INI
		 end
	  end
   end

   -- Validaci�n 4. campo @w_fecha_ven
   if @w_primer_div = 'N'
   begin
      select @w_fecha1 = CONVERT(date, @w_fecha_ven),
	         @w_fecha2 = CONVERT(date, @w_fecha_ven_ant)

	  if (@w_fecha1 = @w_fecha2) or (@w_fecha1 < @w_fecha2)
	  begin
	     if @w_err3 = 0
	     begin
		    print 'Error @w_fecha_ven: '
	        select @w_error_ini = 'S',
	               @w_msg_error = 'Las fechas no tienen orden creciente o son iguales a una existente'

	        goto ERR_VALIDACION_INI
		 end
	  end
   end

   -- Validaci�n 5. campo cuota capital
   if @w_primer_div = 'S'
   begin
      select @w_cuota_cap1 = sum(am_cuota + am_gracia)
      from cob_cartera..ca_amortizacion,cob_cartera..ca_rubro_op
      where am_operacion = @w_num_operacion
        and am_dividendo >= @w_dividendo
        and ro_operacion = @w_num_operacion
        and ro_concepto = am_concepto
        and ro_tipo_rubro = 'C'

      select @w_cuota_cap2 = sum(atm_cuota_capital)
	  from ca_archivo_tabla_manual
	  where atm_banco = @w_banco

	  if @w_cuota_cap1 != @w_cuota_cap2
	  begin 
	     print 'Error Cuota capital: '
	     select @w_error_ini = 'S',
	            @w_msg_error = 'La sumatoria de los rubros capital de la tabla temporal no es igual a la sumatoria de los rubros capital del prestamo'

	     goto ERR_VALIDACION_INI
	  end
   end

   
   ERR_VALIDACION_INI:
	  if @w_error_ini = 'S'
	  begin
	     insert into ca_log_carga_manual
	     values (@w_banco, 1, @w_msg_error)
	  end
	  
   if (@w_count = @w_rows_cursor) and (@w_banco = @w_banco_ant)
   begin
      if not exists(select 1 
	                from ca_log_carga_manual 
					where lcm_banco = @w_banco_ant)
	  begin
	     select @w_paso_temp = 'S'
	     print 'Pasa a temp: ' + convert(varchar(15), @w_banco_ant)

		 goto PASO_TEMP
	  end
   end

   if (@w_count = @w_rows_cursor) and (@w_banco != @w_banco_ant)
   begin
      select @w_banco_ant = @w_banco

      if not exists(select 1 
	                from ca_log_carga_manual 
					where lcm_banco = @w_banco_ant)
	  begin
	     select @w_paso_temp = 'S'
	     print 'Pasa a temp: ' + convert(varchar(15), @w_banco_ant)

		 goto PASO_TEMP
	  end
   end

   select @w_error_ini = 'N',
          @w_primer_div = 'N',
		  @w_count = @w_count + 1,
	      @w_banco_ant = @w_banco,
		  @w_dividendo_ant = @w_dividendo,
		  @w_fecha_ven_ant = @w_fecha_ven,
		  @w_num_ope_ant = @w_num_operacion


   fetch next from cur_difer_masivos into
	  @w_banco,      @w_dividendo,
      @w_fecha_ven,  @w_cuota_cap


   PASO_TEMP:
      if @w_paso_temp = 'S'
	  begin
	     BEGIN TRAN

		 delete ca_op_renovar_tmp
         where ot_user = 'op_batch'
           and ot_term = '10.10.10.10'

		 if @@error != 0
		 begin
		    print 'Error delete ca_op_renovar_tmp'
		 end

		 insert into ca_op_renovar_tmp
         select 'op_batch', '10.10.10.10', @w_num_ope_ant, 0, 'S'

		 exec @w_return = sp_crear_tmp
              @s_user            = 'op_batch',
              @s_term            = '10.10.10.10', 
              @i_banco           = @w_banco_ant,
              @i_accion          = 'R',
              @i_bloquear_salida = 'S',   
              @i_saldo_reest     = 0   

         if @w_return <> 0
         begin
            print 'Error al momento de sp_crear_tmp ' + convert(varchar(15), @w_return) 
			ROLLBACK TRAN

			goto SIGUIENTE
         end
		 else
		 begin
		    select @w_plazo_rest = count(1)
			from ca_archivo_tabla_manual
			where atm_banco = @w_banco_ant

		    exec @w_return = sp_modificar_operacion_int
                 @s_user           = 'op_batch',
				 @s_ofi            = 1,
                 @s_term           = '10.10.10.10',
                 @i_monto          = 0,
                 @i_calcular_tabla = 'S',
                 @i_tabla_nueva    = 'S',
                 @i_salida         = 'N',
                 @i_operacionca    = @w_num_ope_ant,
                 @i_banco          = @w_banco_ant,
                 @i_cuota          = 0, 
                 @i_tplazo         = 'M', --MODIFICAR CREACION DE OPERACIONES PARA QUE SIEMPRE GUARDE EL TIPO DE PLAZO EN MESES
                 @i_plazo          = @w_plazo_rest,
                 @i_tipo_reest     = 'D',
                 @i_fecha_ini      = @w_fecha_ini  --Fecha del primer dividendo

		    if @w_return <> 0
            begin
               print 'Error en sp_modificar_operacion_int ' + convert(varchar(15), @w_return)
			   ROLLBACK TRAN

			   goto SIGUIENTE
            end
			else
			begin
			   select @w_min_div = min(atm_dividendo) 
			   from ca_archivo_tabla_manual 
			   where atm_banco = @w_banco_ant

               select @w_equival = @w_min_div - 1

			   select @w_cant_divs = count(1)
			   from ca_dividendo_tmp
			   where dit_operacion = @w_num_ope_ant


			   while 1 = 1
			   begin
			      
			      select @w_str_gen = ''

			      select top 1
                         @w_div_proc = dit_dividendo
                  from ca_dividendo_tmp
                  where dit_operacion = @w_num_ope_ant
                    AND dit_dividendo > @w_div_proc

				  IF @@ROWCOUNT = 0 BREAK

				  while @w_count_divs <= @w_cant_divs
				  begin
				     
				    select @w_str_div = ''

				    select top 1
                         @w_fecha_ven_proc = dit_fecha_ven
                    from ca_dividendo_tmp
                    where dit_operacion = @w_num_ope_ant
                      AND dit_dividendo = @w_count_divs

 			         if exists (select 1 from ca_archivo_tabla_manual where atm_banco = @w_banco_ant AND atm_dividendo = (@w_div_proc + @w_equival))
						and @w_count_divs = @w_div_proc
                     begin
                        select @w_fecha_ven_proc = atm_fecha_ven,
                               @w_valor_proc = atm_cuota_capital
                        from ca_archivo_tabla_manual 
				   	 where atm_banco = @w_banco_ant 
				   	   and atm_dividendo = (@w_div_proc + @w_equival)
                     end
   
				     select @w_cont_rubs = count(1) 
				     from ca_amortizacion_tmp
                     where amt_operacion = @w_num_ope_ant
                       and amt_dividendo = @w_div_proc
   
				     select @w_str_rubs = ''
				     
				     while @w_cont_rubs > 0
				     begin 
				     
				        set rowcount @w_cont_rubs
   
                        select @w_other_val_proc = amt_cuota,
                               @w_tipo_rub_proc = rot_tipo_rubro
                        from ca_amortizacion_tmp, ca_rubro_op_tmp
                        where amt_operacion = @w_num_ope_ant
                          and amt_operacion = rot_operacion
                          and amt_concepto = rot_concepto
                          and amt_dividendo = @w_count_divs
						order by rot_tipo_rubro desc
                        
                        set rowcount 0
   
				   	 if @w_tipo_rub_proc = 'C' and @w_count_divs = @w_div_proc
                        begin
                           select @w_rub_cap_final = @w_valor_proc
                        end
                        else if @w_tipo_rub_proc = 'C' AND @w_count_divs != @w_div_proc
                           select @w_rub_cap_final = @w_other_val_proc
   
				   	 if @w_tipo_rub_proc <> 'C'
                           select @w_str_rubs = @w_str_rubs + ';' + convert(varchar(20), @w_other_val_proc)
   
				   	 select @w_cont_rubs = @w_cont_rubs - 1
				     end --End while interno
   
				     
				     if @w_count_divs = 1
                        select @w_saldo_proc = @w_cuota_cap1
                     else
                        select @w_saldo_proc = @w_saldo_proc - @w_cuo_cap_ant
   
                     if @w_count_divs = @w_div_proc
                        select @w_cuo_cap_ant = @w_valor_proc
					 else
					    select @w_cuo_cap_ant = @w_rub_cap_final
   
   
				     select @w_str_div = convert(varchar(12), @w_fecha_ven_proc, 101) + ';'
				                       + convert(varchar(15), @w_saldo_proc) + ';'
				   					+ convert(varchar(15), @w_rub_cap_final) + ''
				   					+ @w_str_rubs + '&'
   
				     select @w_str_gen = @w_str_gen + @w_str_div,
				            @w_count_divs = @w_count_divs + 1
   
				     --Creaci�n de @i_str
			         print @w_str_gen
			         --Llamado a sp_decoficador

				  end -- End otro while

				  select @w_count_str = 1,
				         @w_cuo_cap_ant = 0

				  while @w_count_str <= 10
                  begin
                     select @w_pos_amp = charindex('&', @w_str_gen)
                  
                     if @w_pos_amp = 0
                     begin
                        select @w_value_str = ''
                     end
					 else 
					 begin
					    select @w_value_str = substring (@w_str_gen, 1, @w_pos_amp)
                  	    select @w_str_gen = substring(@w_str_gen, (@w_pos_amp + 1), datalength(@w_str_gen) - @w_pos_amp)
					 end

					 if @w_count_str = 1
					    select @w_str1 = @w_value_str
					 else if @w_count_str = 2
					    select @w_str2 = @w_value_str
					 else if @w_count_str = 3
					    select @w_str3 = @w_value_str
					 else if @w_count_str = 4
					    select @w_str4 = @w_value_str
					 else if @w_count_str = 5
					    select @w_str5 = @w_value_str
					 else if @w_count_str = 6
					    select @w_str6 = @w_value_str 
					 else if @w_count_str = 7
					    select @w_str7 = @w_value_str 
					 else if @w_count_str = 8
					    select @w_str8 = @w_value_str 
					 else if @w_count_str = 9
					    select @w_str9 = @w_value_str 
					 else if @w_count_str = 10
					    select @w_str10 = @w_value_str

					 select @w_count_str = @w_count_str + 1

                  end

				  --SP DECODIFICADOR
				  exec @w_return = sp_decodificador
				  @s_user      = 'op_batch',
				  @s_term      = '10.10.10.10',
				  @s_ofi       = 1,
				  @s_date      = '07/06/2021',
				  @s_sesn      = 28298,
                  @i_operacion = @w_num_ope_ant,
                  @i_fila      = 1,
                  @i_accion    = 'A',
                  @i_fecha_ini = @w_fecha_ini,
                  @i_dias_anio = 360,
                  @i_str1      = @w_str1,
                  @i_str2      = @w_str2,
                  @i_str3      = @w_str3,
                  @i_str4      = @w_str4,
                  @i_str5      = @w_str5,
                  @i_str6      = @w_str6,
                  @i_str7      = @w_str7,
                  @i_str8      = @w_str8,
                  @i_str9      = @w_str9,
				  @i_str10     = @w_str10

				  if @w_return <> 0
                  begin
                     print 'Error en sp_decodificador ' + convert(varchar(15), @w_return)
			         ROLLBACK TRAN

					 goto SIGUIENTE
                  end

				  select @w_count_divs = 1
			   end -- End While Externo

			   select @w_div_proc = 0

			   exec cob_cartera..sp_crea_reestructura
               @i_operacion = 'R',
               @i_banco     = @w_banco_ant,
               @s_user      = 'op_batch',
               @s_term      = '10.10.10.10',
               @s_ofi       = 1,
               @s_ssn       = 1875709,
               @s_date      = '07/06/2021',
               @s_sesn      = 19663

			   if @w_return <> 0
               begin
                  print 'Error en sp_crea_reestructura ' + convert(varchar(15), @w_return)
			      ROLLBACK TRAN

			      goto SIGUIENTE
               end

			   delete ca_op_renovar_tmp
               where ot_user = 'op_batch'
                 and ot_term = '10.10.10.10'
			end	
		 end

		 COMMIT TRAN

		 SIGUIENTE:
		 print '====Count: ' + convert(varchar(15), @w_count)
		 select @w_paso_temp = 'N'

		 if (@w_count = @w_rows_cursor) and (@w_banco_ant = @w_banco)
		    break
		 else
		    goto CONTINUACION
	  end
end

close cur_difer_masivos	
deallocate cur_difer_masivos

exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = @w_tipo_bcp,      --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_path_destino,   --ruta y nombre de archivo
     @i_separador       = @w_separador   --separador

truncate table cob_cartera..ca_archivo_tabla_manual

return 0

go
