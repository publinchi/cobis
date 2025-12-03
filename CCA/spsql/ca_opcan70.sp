/***********************************************************************/
/*  Archivo:            ca_opcan70.sp                                  */
/*  Stored procedure:   sp_opcan70                                     */
/*  Base de Datos:      cob_cartera                                    */
/*  Producto:           Cartera                                        */
/*  Disenado por:       Geoconda Yánez                                 */
/***********************************************************************/
/*      IMPORTANTE                                                     */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  'MACOSA',representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*      PROPOSITO                                                      */
/*  Procedimiento para realizar validaciones de notas y porcentajes    */
/***********************************************************************/
/*      MODIFICACIONES                                                 */
/*  FECHA            AUTOR                RAZON                        */
/*  21/Ene/10       Geoconda Yánez        Emision Inicial              */
/***********************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name='sp_opcan70')
drop procedure sp_opcan70
go


create proc sp_opcan70
(
  @i_param1  datetime

)

as

declare 

@w_oficina           smallint,
@w_monto_aprobado    money,
@w_operacion         int,        
@w_banco             cuenta,            
@w_cliente           int,          
@w_porcentaje        float,   
@w_plazo             smallint,
@w_tdividendo        catalogo,
@w_nombre            varchar(255),
@w_apellido_s        varchar(255),
@w_apellido_p        varchar(255),
@w_saldo_capital     money,
@w_nota              int,
@w_cedula            varchar(64),
@w_fecha_negocio     datetime,
@w_antiguedad        int,
@w_actividad         catalogo,
@w_nom_actividad     varchar(64),
@w_ejecutivo         smallint,
@w_nom_ejecutivo     varchar(64),
@w_dir_negocio       varchar(254),
@w_telefono_c        varchar(16),
@w_telefono_n        varchar(16), 
@w_apellidos         varchar(255),
@w_error             int,
@w_tplazo            char(1),
@w_plazo_mensual     int,
@w_factor            int,
@w_est_vigente       tinyint,
@w_est_vencido       tinyint,
@w_est_novigente     tinyint,
@w_est_cancelado     tinyint,
@w_est_credito       tinyint,
@w_est_suspenso      tinyint,
@w_est_castigado     tinyint,
@w_est_anulado       tinyint,
@w_est_diferido      tinyint,
@w_est_condonado     tinyint

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out


/************************************************************/
-- SE TRUNCAN LAS TABLAS DE TRABAJO
/************************************************************/
truncate table ca_temp_div_total
truncate table ca_temp_div_parcial
truncate table ca_temp_porcentaje
truncate table ca_rep_70

/************************************************************/
-- ENCUENTRA LOS DATOS DE TOTALES DE DIVIDENDOS POR OPERACION
/************************************************************/

insert into ca_temp_div_total
select count(di_dividendo),di_operacion 
from   ca_dividendo, ca_operacion
where  op_operacion  =  di_operacion
and    op_estado not in (@w_est_novigente,@w_est_credito,@w_est_castigado,@w_est_anulado)
group by di_operacion

/************************************************************/
-- ENCUENTRA LOS DATOS DE DIVIDENDOS CANCELADOS POR OPERACION 
/************************************************************/
insert into ca_temp_div_parcial
select count(di_dividendo),di_operacion 
from   ca_dividendo, ca_operacion
where  di_estado = 3
and    di_operacion  =  op_operacion
and    op_estado not in (@w_est_novigente,@w_est_credito,@w_est_castigado,@w_est_anulado)
group by di_operacion
  
/************************************************************/
-- OBTIENEN PORCENTAJES DE PAGO POR OPERACION
/************************************************************/  
insert into ca_temp_porcentaje
select round((a.count_div_2/b.count_div_1)*100,0),
        a.operacion_2 
from cob_cartera..ca_temp_div_parcial a , 
     cob_cartera..ca_temp_div_total b
where a.operacion_2=b.operacion_1

/*****************************************************************/
-- CURSOR PARA ENCONTRAR LOS VALORES QUE FALTAN DE LAS OPERACIONES
-- PREVIAMENTE SELECCIONADAS PORQUE CUMPLEN > 70%
/****************************************************************/
declare cursor_opera cursor for  select 
op_oficina,    op_operacion,       op_banco,
op_cliente,    op_monto_aprobado,  porcentaje,
op_plazo,      op_tdividendo,      op_tplazo,
op_oficial
from  ca_temp_porcentaje,    ca_operacion
where porcentaje >=70 and porcentaje < 100
and   op_operacion=operacion
order by operacion 

for read only

open cursor_opera

fetch cursor_opera into 

@w_oficina,		@w_operacion, 		@w_banco,
@w_cliente,     @w_monto_aprobado,  @w_porcentaje,
@w_plazo,       @w_tdividendo,      @w_tplazo,
@w_ejecutivo

while   @@fetch_status = 0 
begin
   if (@@fetch_status = -1) 
   begin
      select @w_error = 710004
      goto ERROR
   end  
   
      
   /************************************************************/
   -- ENCUENTRA LOS DATOS DEL PLAZO
   /************************************************************/ 
   
   select @w_plazo_mensual = @w_plazo * (select td_factor from ca_tdividendo where td_tdividendo = @w_tplazo) / 30
     
   
   /************************************************************/
   -- ENCUENTRA LOS DATOS DEL CLIENTE DUEÑO DE LA OPERACION
   /************************************************************/             
   select @w_apellidos = ' '
   
   select 
   @w_nombre        = en_nombre,
   @w_apellido_p    = p_p_apellido,
   @w_apellido_s    = p_s_apellido,             
   @w_cedula        = en_ced_ruc,
   @w_fecha_negocio = en_fecha_negocio,  
   @w_actividad     = en_actividad         
   from cobis..cl_ente
   where en_ente=@w_cliente          
     
   select @w_apellidos=@w_apellido_p + ' ' + @w_apellido_s
   
   /************************************************************/
   -- ENCUENTRA LOS DATOS DE ANTIGUEDAD DEL NEGOCIO.
   /************************************************************/
   
   select @w_antiguedad= datediff(mm,@w_fecha_negocio,@i_param1)
      
   
   /************************************************************/
   -- ENCUENTRA LOS DATOS DE SALDO CAPITAL DE LA OPERACION
   /************************************************************/
   select @w_saldo_capital=0
   
   select @w_saldo_capital = sum(am_cuota+am_gracia -am_pagado) 
     from cob_cartera..ca_amortizacion,
          cob_cartera..ca_dividendo
    where am_operacion=di_operacion
      and am_concepto='CAP'
      and am_dividendo=di_dividendo
      and di_operacion=@w_operacion
  
  /************************************************************/
  -- ENCUENTRA LOS DATOS DE CALIFICACION DEL CLIENTE
  /************************************************************/ 
   select @w_nota = 0
  
   select @w_nota = isnull(min(ci_nota),0)
    from cob_credito..cr_califica_int_mod
   where ci_cliente=@w_cliente
  
  /************************************************************/
  -- ENCUENTRA LOS DATOS DE ACTIVIDAD DEL CLIENTE
  /************************************************************/
   select @w_nom_actividad = ''
   
   select @w_nom_actividad= aa_descripcion
     from cobis..cl_asociacion_actividad
    where aa_actividad=@w_actividad
    
  /************************************************************/  
  -- ENCUENTRA LOS DATOS DE OFICIAL DEL CLIENTE
  /************************************************************/  
    
   select  @w_nom_ejecutivo = fu_nombre
   from  cobis..cc_oficial,
         cobis..cl_funcionario,
         cobis..cl_catalogo
   where oc_oficial       = @w_ejecutivo
   and   oc_funcionario   = fu_funcionario 
   and   codigo           = oc_tipo_oficial
   and   tabla = (select codigo 
                  from cobis..cl_tabla
                  where tabla = 'cc_tipo_oficial')

  
  /************************************************************/
  -- ENCUENTRA LOS DATOS DE DIRECCIONES Y TELEFONOS DEL CLIENTE
  -- 002 DOMICILIO
  -- 011 NEGOCIO
  /************************************************************/  
  
   select @w_dir_negocio = '',
          @w_telefono_n  = '',
          @w_telefono_c  = ''
   
   select @w_dir_negocio = isnull(di_descripcion,''),
          @w_telefono_n  = isnull(te_valor,'')
     from cobis..cl_direccion,
          cobis..cl_telefono
   where di_tipo='011'       --NEGOCIO  
     and di_direccion=te_direccion
     and di_ente=te_ente
     and di_ente=@w_cliente
      
  
   select @w_telefono_c=te_valor
     from cobis..cl_direccion,
          cobis..cl_telefono            
    where di_tipo='002'       --CASA
      and di_direccion=te_direccion
      and di_ente=te_ente
      and di_ente=@w_cliente
                                                       
    /************************************************************/
    -- INSERCION DE LOS DATOS E INFORMACION PARA GENERACION DE
    -- REPORTE.
    /************************************************************/    
    insert into ca_rep_70 (
    cr_oficina,        cr_banco,         cr_cedula, 
    cr_nombre,         cr_apellido,      cr_monto, 
    cr_plazo,          cr_saldo,         cr_nota,
    cr_porcentaje,     cr_antiguedad,    cr_actividad,
    cr_direccion,      cr_telefono_n,    cr_telefono_c,
    cr_ejecutivo                         
    )                                    
    values(                              
    @w_oficina,        @w_banco,         @w_cedula, 
    @w_nombre,         @w_apellidos,     @w_monto_aprobado,
    @w_plazo_mensual,  @w_saldo_capital, @w_nota,
    @w_porcentaje,     @w_antiguedad,    @w_nom_actividad,
    @w_dir_negocio,    @w_telefono_n,    @w_telefono_c,
    @w_nom_ejecutivo   
    )
         
   -- Si hubiere error en la inserción de datos.
    
    if @@error > 0
    begin
    	 print 'No se pudo generar información Operacion: ' + @w_banco + ' Cliente: ' + cast(@w_cliente as varchar)
    end	   
    
   -- Siguiente registro del cursor.
                      
   fetch cursor_opera into  
   @w_oficina,              
   @w_operacion,            
   @w_banco,                
   @w_cliente,              
   @w_monto_aprobado,       
   @w_porcentaje,
   @w_plazo,
   @w_tdividendo,
   @w_tplazo ,
   @w_ejecutivo
   
end -- While de fetch status cur_opera

ERROR:
close cursor_opera
deallocate cursor_opera

return 0
go
