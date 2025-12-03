/************************************************************************/
/*   NOMBRE LOGICO:      recalcula_rubros_enl.sp                        */
/*   NOMBRE FISICO:      sp_recalcula_rubros_enl                        */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Octubre 2023                                   */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Programa para gestionar recalculo de rubros para la versión Enlace  */
/*  D: Respalda y Elimina rubros                                        */
/*  I: Insertar rubros                                                  */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  FECHA        AUTOR             RAZON                                */
/*  18/10/2022   Kevin Rodríguez   Emisión inicial                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recalcula_rubros_enl')
    drop proc sp_recalcula_rubros_enl
go
create proc sp_recalcula_rubros_enl
   @s_user                       login         = null,
   @s_date                       datetime      = null,
   @s_term                       varchar(30)   = null,
   @s_ofi                        smallint      = null,
   @i_operacion                  char(1)       = null,
   @i_banco                      varchar(24),
   @i_tdividendo                 catalogo,
   @i_periodo_int                smallint,
   @i_recalc_rubs_enl            char          = 'S',
   @o_recalculo_rubs             char(1)       = null out
   
as

declare
@w_sp_name         descripcion,
@w_error           int,
@w_operacionca     int,
@w_tdividendo      catalogo,
@w_periodo_int     smallint,
@w_grupal          char(1),
@w_grupo           int,
@w_n_rubros        int,
@w_contador        int,
@w_concepto        varchar(10),
@w_n_rubros_eli    INT,
@w_porcentaje      float,
@w_valor		   money
   
   
-- CARGAR VALORES INICIALES
select @w_sp_name = 'sp_recalcula_rubros_enl'

select @w_tdividendo     = opt_tdividendo,
       @w_periodo_int    = opt_periodo_int,
       @w_operacionca    = opt_operacion,
	   @w_grupal         = opt_grupal,
	   @w_grupo          = opt_grupo
from   cob_cartera..ca_operacion_tmp with (nolock)
where  opt_banco = @i_banco


if @i_operacion = 'D'
begin

   -- KDR Proceso de recalculo de valor de rubros calculados, cuando se cumplan las condiciones siguientes (Versión Enlace)
   --     - El préstamo tiene asociado un rubro contenido en el catálogo de rubros aptos para el recalculo de su valor
   --     - Existe un cambio del tipo de dividendo en la operación.
   --     - Y cuando la bandera de realizar el proceso de recalculo de rubros esta activada (sp_xsell_actualiza_monto_op ya 
   --       hace un proceso similar, por lo cual este programa envia 'N' en este parámetro)	
   if not ((@w_tdividendo <> @i_tdividendo
             or @i_periodo_int <> @w_periodo_int)
           and @i_recalc_rubs_enl = 'S')
   begin
      select @o_recalculo_rubs = 'N'
      goto SALIR
   end

   create table #rubros_eliminar(
   id_num     int identity(1,1), 
   concepto   varchar     (10))

   if object_id('tempdb..##ca_respaldo_rubros') is not null
      drop table ##ca_respaldo_rubros
	  
   -- Respaldo de rubros
   select
   rot_operacion,      
   rot_concepto,        
   rot_tipo_rubro,           
   rot_fpago,        
   rot_prioridad, 
   rot_paga_mora, 
   rot_provisiona,     
   rot_signo,           
   rot_factor,              
   rot_referencial,  
   rot_valor,     
   rot_porcentaje, 
   rot_signo_reajuste, 
   rot_factor_reajuste, 
   rot_referencial_reajuste, 
   rot_base_calculo, 
   rot_num_dec,   
   rot_financiado
   into ##ca_respaldo_rubros
   from ca_rubro_op_tmp with (nolock)
   where rot_operacion = @w_operacionca 
   and rot_tipo_rubro in ('O','Q','V')
   and rot_concepto in (select c.codigo
                        from cobis..cl_tabla t, cobis..cl_catalogo c
                        where t.tabla = 'ca_recalculo_rubros_enlace'
                        and t.codigo = c.tabla)

   if @@rowcount = 0
   begin
      select @o_recalculo_rubs = 'N'
	  goto SALIR
   end      

   insert into #rubros_eliminar
   select rot_concepto
   from ##ca_respaldo_rubros 
   where rot_operacion = @w_operacionca 
   order by rot_concepto
     
   select @w_n_rubros_eli = count(1),
          @w_contador     = 1
   from ##ca_respaldo_rubros 
   where rot_operacion = @w_operacionca
   
   select top 1 @w_concepto = concepto
   from  #rubros_eliminar
   order by id_num  
   
   while @w_contador <= @w_n_rubros_eli
   begin 
   									  		   
      -- Eliminación de rubro
      exec @w_error = sp_rubro_tmp
   	  @s_user      = @s_user,
   	  @s_term      = @s_term,
   	  @s_date      = @s_date,
   	  @s_ofi       = @s_ofi,
   	  @i_banco     = @i_banco,
   	  @i_concepto  = @w_concepto,
   	  @i_operacion = 'D'
	  
   	  if @w_error <> 0 
	     return @w_error
   	  
   	  if @w_contador = @w_n_rubros_eli
         break
   	   	
      select @w_contador = @w_contador + 1
         		    
      select @w_concepto = concepto
      from  #rubros_eliminar
      where id_num = @w_contador
   
   end

   select @o_recalculo_rubs = 'S'   
	
end

if @i_operacion = 'I'
begin

   create table #rubros_actualizar(
   id_num     int identity(1,1), 
   concepto   varchar     (10),
   financiado CHAR        (1),
   porcentaje float,
   valor      money)

   insert into #rubros_actualizar
   select rot_concepto,
          rot_financiado,
          rot_porcentaje,
          rot_valor   
   from ##ca_respaldo_rubros 
   where rot_operacion = @w_operacionca 
   order by rot_concepto
   
   select @w_n_rubros = count(1),
          @w_contador     = 1
   from ##ca_respaldo_rubros 
   where rot_operacion = @w_operacionca 
      
   select top 1 @w_concepto = concepto,
                @w_porcentaje = porcentaje,
   			    @w_valor = valor
   from  #rubros_actualizar
   order by id_num 
   
   while @w_contador <= @w_n_rubros 
   begin 
														  			      
      -- Registro de Rubro
      exec @w_error = sp_rubro_tmp
      @s_user       = @s_user,
      @s_term       = @s_term,
      @s_ofi        = @s_ofi,
      @s_date       = @s_date,
      @i_banco      = @i_banco,
      @i_operacion  = 'I',
      @i_porcentaje = @w_porcentaje,
      @i_valor      = @w_valor,
      @i_concepto   = @w_concepto
      
      if @w_error <> 0 
        return @w_error
						  
      exec @w_error = sp_modificar_operacion
      @s_user              = @s_user,
      @s_date              = @s_date,
      @s_ofi               = @s_ofi,
      @s_term              = @s_term,
      @i_calcular_tabla    = 'S', 
      @i_tabla_nueva       = 'S',
      @i_regenera_rubro    = 'N',
      @i_cuota             = 0,                 -- KDR Para recalcular cuota según nuevo monto
      @i_operacionca       = @w_operacionca,
      @i_banco             = @i_banco,
      @i_grupo             = @w_grupo ,
      @i_grupal            = @w_grupal,
	  @i_recalc_rubs_enl   = 'N'
         
      if @w_error <> 0 
        return @w_error
					   	    		  		                
      if @w_contador = @w_n_rubros
         break
				
      select @w_contador = @w_contador + 1
      
      select @w_porcentaje = 0,
                @w_valor = 0
      	   
      select @w_concepto = concepto,
      	     @w_porcentaje = porcentaje,
      	     @w_valor = valor
      from  #rubros_actualizar
      where id_num = @w_contador
	
   end

end

SALIR:
return 0

ERROR:
return @w_error

go

