/************************************************************************/
/*  Archivo:                var_calif_buro_cred_int.sp                   */
/*  Stored procedure:       sp_var_calif_buro_cred_int                   */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_var_calif_buro_cred_int' and type = 'P')
   drop proc sp_var_calif_buro_cred_int
go

create proc sp_var_calif_buro_cred_int(
@i_ente       INT,
@o_resultado  VARCHAR(255) = NULL OUTPUT
)
as
declare @w_sp_name                          varchar(64),
        @w_error                            int,
        @w_tramite                          int,
        @w_num_miembros                     int,
        @w_resultado                        varchar(255),
        @w_asig_actividad                   int,        
        @w_valor_ant                        varchar(255),
        @w_valor_nuevo                      varchar(255),
        @w_cliente                          INT,
        @w_resultado_ciclo                  INT,
        @w_nro_ciclo                        INT,
        @w_fecha_ult_consulta               datetime,
        @w_fecha                            datetime,
        @w_meses                            int     ,
        @w_numero_cuentas                   int     ,
        @w_determinante                     char(1) ,
        @w_fecha_proceso                    datetime     
        

select 
@w_sp_name = 'sp_var_buro_credito_indiv',
@w_resultado    = 'BUENO',
@w_determinante = 'S'
/*DETERMINAR EL CICLO DEL CLIENTE*/
exec @w_error  = cob_credito..sp_nro_ciclo_cliente
@t_debug       = 'S',
@t_file        = null,
@t_from        = null,
@i_cliente     = @i_ente,
@o_resultado   = @w_nro_ciclo OUTPUT

if @w_error <> 0 GOTO ERROR 


--print 'CICLO CLIENTE: ' + convert(varchar, @w_nro_ciclo )   
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

SELECT 
@w_fecha_ult_consulta = isnull(max(ib_fecha),'01/01/1900')
FROM cr_buro_cuenta,cr_interface_buro
where  bc_id_cliente = ib_cliente
and    bc_id_cliente = @i_ente

if @w_fecha_ult_consulta = '01/01/1900' begin   
   SELECT @w_resultado = 'BUENO' 
   GOTO ACTUALIZAR
   
end


SELECT 
ib_cliente AS bc_id_cliente,
ib_fecha AS bc_fecha_actualizacion,
bc_forma_pago_actual,bc_historico_pagos,
--bc_saldo_actual,bc_tipo_contrato,
bc_nombre_otorgante,
bc_clave_observacion,bc_saldo_actual,
bc_saldo_vencido,bc_tipo_contrato,bc_fecha_apertura_cuenta = convert(datetime,SUBSTRING(bc_fecha_apertura_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_apertura_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_apertura_cuenta,5,4),103)
INTO #cr_buro_cuenta
FROM cr_buro_cuenta,cr_interface_buro
WHERE bc_id_cliente = ib_cliente
and  bc_id_cliente = @i_ente
and ((bc_fecha_cierre_cuenta is null or bc_fecha_cierre_cuenta = '01010001' or
      datediff(mm,(convert(datetime,SUBSTRING(bc_fecha_cierre_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_cierre_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_cierre_cuenta,5,4),103)),@w_fecha_proceso) <=12) 
or bc_forma_pago_actual = '99'
)--and  bc_fecha_actualizacion = @w_fecha_ult_consul
if @@error <> 0 GOTO ERROR


if @w_nro_ciclo = 1
begin
      -- Eliminacion del universo 
      -- Excluir cuentas financieras <=100  
      delete
      from #cr_buro_cuenta
      where  convert(money,replace(replace(bc_saldo_vencido,'+',''),'-','')) <= 500
      and     bc_forma_pago_actual in ('04', '05', '06', '07', '96', '97')
      and    ltrim(rtrim(bc_nombre_otorgante)) not in (select ltrim(rtrim(c.valor)) 
                                                       from cobis..cl_tabla t,cobis..cl_catalogo c
                                                       where t.tabla  = 'cr_tipo_negocio'
                                                       and   t.codigo = c.tabla  
                                                       )   
                                                   
      -- Excluir cuentas no financieras con saldos vencidos hasta $1,000
      delete
      from #cr_buro_cuenta
      where  convert(money,replace(replace(bc_saldo_vencido,'+',''),'-','')) <= 2000
      and    ltrim(rtrim(bc_nombre_otorgante)) in (select ltrim(rtrim(c.valor)) 
                                                   from cobis..cl_tabla t,cobis..cl_catalogo c
                                                   where t.tabla  = 'cr_tipo_negocio'
                                                   and   t.codigo = c.tabla  
                                                   )      
      -- Excluir cuentas creadas recientemente sin calificacion.
      delete
      from #cr_buro_cuenta
      where  bc_forma_pago_actual in ('00', 'UR')
end


--SELECT 'REGISTRO DEL CLIENTE TABLA BURO'
SELECT  bc_id_cliente AS CLIENTE,  bc_forma_pago_actual AS MOP, bc_saldo_vencido AS MONTO  , bc_historico_pagos AS RETRASO, bc_tipo_contrato AS TIPO_CONTRATO,
        bc_clave_observacion AS CLAVES_PREVENCION, bc_fecha_apertura_cuenta AS FECHA_APERTURA,  bc_nombre_otorgante AS TIPO_NEGOCIO, bc_saldo_actual AS SALDO_ACTUAL ,@w_nro_ciclo AS CICLO
FROM #cr_buro_cuenta

if @w_nro_ciclo = 1 and (exists (select 1 
           from  #cr_buro_cuenta 
           where bc_clave_observacion in ('FD','SG','IM','LO','FR') 
           or    bc_forma_pago_actual='99') 
   or 
   exists (select 1 
           from  #cr_buro_cuenta    
           where bc_forma_pago_actual in ('04', '05', '06', '07')  
           and   convert(money,replace(replace(bc_saldo_vencido,'+',''),'-','')) >= 500) )         
begin            
      PRINT 'xxxxxxxxx A xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)     
      select @w_resultado = 'MALO'       
end 
else
begin
    
   if exists(select 1 from  #cr_buro_cuenta 
             where bc_tipo_contrato in ('RE','SM', 'HE')    --RE Bienes raices, SM  Segunda Hipoteca , HE  PrÚstamo tipo Home Equity
             and bc_forma_pago_actual not in ('01'))
   begin        
            PRINT 'xxxxxxxxx B xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)
            select @w_resultado = 'MALO'              
   end        
   else          
   begin        
            if exists(select 1 from  #cr_buro_cuenta 
                      where bc_tipo_contrato in  ('AU', 'RV')        --AU Compra de Auotomovil, RV VehÝculo Recreativo  
                      and bc_forma_pago_actual not in ('01', '02') )      
            begin
			          PRINT 'xxxxxxxxx C xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)
                      select @w_resultado = 'MALO'              
            end    
            else   
            begin  
                      if @w_nro_ciclo = 1 and
                         exists (select 1 from  #cr_buro_cuenta 
                                 where (bc_forma_pago_actual in ('02','03'))
                                 and  convert(money,replace(replace(bc_saldo_vencido,'+',''),'-','')) > 10000 )        
                      begin 
					            PRINT 'xxxxxxxxx D xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)
                                 select @w_resultado    = 'MALO'                                                                                                                                       
                      end
                      else
                      begin     
                              if @w_nro_ciclo = 1 and
                                 exists (select 1 from  #cr_buro_cuenta 
                                         where bc_forma_pago_actual  not in ('01','02','03'))
                              begin
							        PRINT 'xxxxxxxxx E xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)
                                    select @w_determinante = 'N'
                                    select @w_resultado = 'MALO'  
                                                                              
                              end         
                       end                             
            end                        
            
  end          
  
  if @w_resultado = 'MALO' and @w_nro_ciclo = 1 and @w_determinante = 'N'
  begin                               
        select @w_numero_cuentas  = 0
        select @w_numero_cuentas = isnull(count(1),0) 
        from  #cr_buro_cuenta 
        where bc_forma_pago_actual in ('02', '03')
        
        if ((select isnull(count(1),0) 
            from  #cr_buro_cuenta 
            where bc_forma_pago_actual in ('02', '03') 
            and   convert(money,replace(replace(bc_saldo_vencido,'+',''),'-','')) <= 10000) = @w_numero_cuentas)
            or @w_numero_cuentas = 0
        begin

              select @w_numero_cuentas  = 0
              select @w_numero_cuentas = isnull(count(1),0) 
              from  #cr_buro_cuenta 
              where bc_forma_pago_actual in ('96','97','98')
                             
							      
              select @w_fecha =min(bc_fecha_apertura_cuenta)
              from  #cr_buro_cuenta 
              where bc_forma_pago_actual in ('01')
              and ltrim(rtrim(bc_nombre_otorgante)) not in (select ltrim(rtrim(c.valor)) 
                                                       from cobis..cl_tabla t,cobis..cl_catalogo c
                                                       where t.tabla  = 'cr_tipo_negocio'
                                                       and   t.codigo = c.tabla  
                                                       )   
        
              select @w_fecha=isnull(@w_fecha,@w_fecha_proceso)
              select @w_meses = datediff(mm,@w_fecha, @w_fecha_proceso) 
              select @w_meses = isnull(@w_meses,0)

			  PRINT '---------->>w_numero_cuentas:' + convert(varchar, @w_numero_cuentas)+'--w_meses:' + convert(varchar, @w_meses)
              if  (@w_numero_cuentas > 0 and @w_numero_cuentas <= 8) and @w_meses >= 3       
              begin 
			      PRINT 'xxxxxxxxx F xxxxxxxxxxxxx - Cliente:' + convert(varchar, @i_ente)
                  select @w_resultado = 'BUENO'
              end                                 
        end 
              
   end   
end 

ACTUALIZAR:   
SELECT @o_resultado = @w_resultado      

print '---->> sp_var_buro_credito_indiv:@o_resultado: ' + convert(varchar, @o_resultado )  + '--Cliente:'+  convert(varchar, @i_ente )
return 0


ERROR:
select @w_error = 6904007 --No existieron resultados asociados a la operacion indicada   
EXEC @w_error= cobis..sp_cerror
@t_debug  = 'N',
@t_file   = '',
@t_from   = @w_sp_name,
@i_num    = @w_error

return @w_error





GO
