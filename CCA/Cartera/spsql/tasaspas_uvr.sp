/****************************************************************************/
/* Este programa lee la tabla  ca_uvr_subir  que sera cargada por el bcp    */
/*  uvr.bcp   para hacer fecha valor hasta mar-01-2004 y actualizar la tabla*/
/* ca_rubro_op con los datos entregados por el BAC hasta la fecha           */
/****************************************************************************/
use cob_cartera
go

--update ca_uvr_subir
--set procesado = 'N'
--go
--insert into ca_uvr_subir values ('8404029112702200411743','726013520165518',574419,'INT','TFIJA','+',5.84,6.00,'E','N')
--go

if exists (select 1 from sysobjects where name = 'sp_tasas_pasivas_uvr')
   drop proc sp_tasas_pasivas_uvr
go

create proc sp_tasas_pasivas_uvr 

as
declare
@w_migrada         cuenta,
@w_banco           cuenta,
@w_operacion       int,   
@w_concepto        catalogo,
@w_referencial     catalogo,
@w_signo           char(1),    
@w_porcentaje_nom  float,   
@w_porcentaje_efa  float,   
@w_tipo_puntos     char(1),
@w_registros       int,
@w_hora            datetime,
@w_error           int

select @w_registros  = 0
 
select @w_hora = convert(char(10), getdate(),8)

--print 'tasaspas_uvr.sp A procesar =' + CAST(@w_registros AS VARCHAR) + ' ' + CAST(@w_hora AS VARCHAR)


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         migrada,
         banco,
         operacion,
         concepto,
         referencial,
         signo,
         porcentaje_nom,
         porcentaje_efa,
         tipo_puntos
         
from ca_uvr_subir 
where procesado = 'N'

open cursor_operacion

fetch cursor_operacion
   into  
      @w_migrada,
      @w_banco,
      @w_operacion,
      @w_concepto,
      @w_referencial,
      @w_signo,
      @w_porcentaje_nom,
      @w_porcentaje_efa,
      @w_tipo_puntos
while @@fetch_status = 0
begin
   
      update ca_uvr_subir
      set procesado = 'S'
      where operacion = @w_operacion
   
   
      select @w_registros =  @w_registros + 1
      
      exec  sp_restaurar
	   @i_banco		= @w_banco
      
      --HACER FECHA VALOR AL DIA DE LA MIGRACION
      exec @w_error = sp_fecha_valor
      @s_date              = '10/27/2004',
      @s_lsrv	     	      = 'PRODUCCION',
      @s_ofi               = 9000,
      @s_sesn              = 1,
      @s_ssn               = 1,
      @s_srv               = 'PRODUCCION',
      @s_term              = 'CONSOLA',
      @s_user              = 'script',
      @i_fecha_valor	      = '03/01/2004',
      @i_banco		         = @w_banco,
      @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
      @i_observacion       = 'FECHA VALOR PARA INCLUIR TASAS DESDE MIGRACION'
                
      if @w_error != 0
      begin
         insert into ca_errorlog
                 (er_fecha_proc,      er_error,      er_usuario,
                  er_tran,            er_cuenta,     er_descripcion,
                  er_anexo)
         values('10/31/2004',        @w_error,      'script',
                  7269,               @w_banco,      'RECALCULO DE INTERESES DESDE LA MIGRACION',
                  null) 
                  
        update ca_uvr_subir
        set procesado = 'E'
        where operacion = @w_operacion
     end
     else
     begin
         delete ca_reajuste
         where re_operacion = @w_operacion
      
         delete ca_reajuste_det
         where red_operacion = @w_operacion

         --ACTUALIZACION DE LA TABLA DE RUBROS
         update ca_rubro_op
         set 
            ro_provisiona = 'S',
            ro_signo      = @w_signo,
            ro_factor     = @w_porcentaje_efa,
            ro_referencial = @w_referencial,
            ro_porcentaje  = @w_porcentaje_nom,
            ro_porcentaje_aux = @w_porcentaje_nom,
            ro_porcentaje_efa = @w_porcentaje_efa,
            ro_tipo_puntos    = @w_tipo_puntos
         where ro_operacion = @w_operacion
         and   ro_concepto = @w_concepto
         
         update ca_rubro_op_his
         set 
            roh_provisiona = 'S',
            roh_signo      = @w_signo,
            roh_factor     = @w_porcentaje_efa,
            roh_referencial = @w_referencial,
            roh_porcentaje  = @w_porcentaje_nom,
            roh_porcentaje_aux = @w_porcentaje_nom,
            roh_porcentaje_efa = @w_porcentaje_efa,
            roh_tipo_puntos    = @w_tipo_puntos
         where roh_operacion = @w_operacion
         and   roh_secuencial = 1
         and   roh_concepto = @w_concepto
         
         
         --ADELANTAR LA OBLIGACION
         
              --HACER FECHA VALOR AL DIA DE LA MIGRACION
            exec @w_error = sp_fecha_valor
            @s_date              = '10/27/2004',
            @s_lsrv	     	      = 'PRODUCCION',
            @s_ofi               = 9000,
            @s_sesn              = 1,
            @s_ssn               = 1,
            @s_srv               = 'PRODUCCION',
            @s_term              = 'CONSOLA',
            @s_user              = 'script',
            @i_fecha_valor	      = '10/27/2004',
            @i_banco		         = @w_banco,
            @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
            @i_observacion       = 'FECHA VALOR PARA IGUALAR CON LAS TASAS'
                      
            if @w_error != 0
            begin
               insert into ca_errorlog
                       (er_fecha_proc,      er_error,      er_usuario,
                        er_tran,            er_cuenta,     er_descripcion,
                        er_anexo)
               values('10/31/2004',        @w_error,      'script',
                        7269,               @w_banco,      'RECALCULO DE INTERESES DESDE LA MIGRACION',
                        null) 
                        
              update ca_uvr_subir
              set procesado = 'E'
              where operacion = @w_operacion
           end
           
         --SE ELIMINAN LOS PLANES DE REAJUSTE SI ESTOS TIENEN PUESTO QUE SON TASAS FIJAS
         --Y NO DEBEN SER ACTUALIZADAS
         
         PRINT 'tasaspas_uvr.sp va procesada  @w_banco' + @w_banco
      end --PROCESO TODO
        
   fetch cursor_operacion
   into  
      @w_migrada,
      @w_banco,
      @w_operacion,
      @w_concepto,
      @w_referencial,
      @w_signo,
      @w_porcentaje_nom,
      @w_porcentaje_efa,
      @w_tipo_puntos

end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

print 'tasaspas_uvr.sp Finalizo  =' + cast(@w_registros as varchar) + ' ' + @w_hora

go

