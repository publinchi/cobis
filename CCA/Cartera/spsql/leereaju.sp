/************************************************************************/
/*	Archivo:		              leereaju.sp				                     */
/*	Stored procedure:	        sp_leer_reajustes			                  */
/*	Base de datos:		        cob_cartera				                     */
/*	Producto: 		           Cartera					                     */
/*	Disenado por:  		     RGA  FDLT      				                  */
/*	Fecha de escritura:	     Ene. 1998 				                     */
/************************************************************************/
/*				                    IMPORTANTE				                  */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	"MACOSA".							                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				                    PROPOSITO				                     */
/*	Lee la cadena descompuesta e inserta en ca_operacion y               */
/*	ca_rubro_op                                                          */
/************************************************************************/  
/*                          ODIFICACIONES                               */
/*   FECHA                      AUTOR           RAZON                   */
/*   ENE-31-2007               EPB              NR-684                  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_leer_reajustes')
	drop proc sp_leer_reajustes
go

create proc sp_leer_reajustes
   @s_date         datetime,
   @s_ofi          int,
   @s_term         varchar(30),
   @s_user         login,
   @s_sesn         int, 
   @i_operacion    int,
   @i_formato_fecha int = 101,
   @i_concepto     catalogo
as

declare 
   @w_sp_name		descripcion,
   @w_error		int,
   @w_return		int,
   @w_fila              int,
   @w_columna           int,
   @w_tot_filas         int,	
   @w_banco		cuenta,
   @w_fecha		datetime,
   @w_referencial       catalogo,
   @w_signo             char(1),
   @w_factor            float,
   @w_porcentaje        float,
   @w_operacion         int,
   @w_repetidos         int,
   @w_reaj_especial     char(1),
   @w_desagio 		char(1),
   @w_tasa_referencial  catalogo,
   @w_sector            char(1),
   @w_operacionca	int,
   @w_secuencial        int,
   @w_cargadas          int
 
/* VARIABLES INICIALES */

select @w_sp_name = 'sp_leer_reajustes',
       @w_cargadas = 0




/* CONTROL DE OPERACIONES REPETIDAS*/
select @w_repetidos = count(*)
from ca_decodificador
where dc_operacion = @i_operacion
and   dc_user = @s_user
and   dc_sesn = @s_sesn
and   dc_columna = 2
group by dc_valor
having count(*) > 1

if @w_repetidos is not null
   return 710028


/* MAXIMO DE FILAS ALMACENADAS*/
select @w_tot_filas = max(dc_fila)
from   ca_decodificador
where  dc_operacion = @i_operacion
and    dc_user      = @s_user
and    dc_sesn      = @s_sesn


--- SECUENCIAL PARA RELACIONAR LAS OPERACIONES CON LA CARTA DE AVISO 
exec @w_secuencial = sp_gen_sec 
     @i_operacion  = -2

select @w_fila = 1
while @w_fila <= @w_tot_filas
begin


   select @w_operacionca = 0

   /*FECHA DE REAJUSTE*/
   select @w_fecha = convert(datetime,dc_valor,@i_formato_fecha)
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 1

   /*BANCO*/
   select @w_banco = dc_valor
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 2


   select @w_operacionca = op_operacion
   from ca_operacion
   where op_banco = @w_banco


   /*REFERENCIAL*/

 
   select @w_referencial = dc_valor
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 3

   if @w_referencial = 'b'
      select @w_referencial = null
   else begin

 /*EPB AGO-29-2001*/ 

  select @w_sector = op_sector,
         @w_operacionca = op_operacion
  from ca_operacion
  where op_banco = @w_banco

  select @w_tasa_referencial =  vd_referencia
         from ca_valor_det
  where vd_tipo = @w_referencial
    and vd_sector = @w_sector 
  if @@rowcount = 0  begin
--     PRINT 'leereju.sp error sacando tasa_referencial' + @w_referencial + 'de ca_valor_det , @w_sector' + @w_sector
    return 701177
  end

  /*FIN EPB AGO-29-2001*/ 

    
      if not exists(select 1
                    from ca_tasa_valor 
                    where tv_nombre_tasa =  @w_tasa_referencial)
         return 701085
   end
   
   /*SIGNO*/
   select @w_signo = dc_valor
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 4

   if @w_signo = 'b'
      select @w_signo = null

   /*FACTOR*/
   select @w_factor = convert(float,dc_valor)
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 5

   /*PORCENTAJE*/
   select @w_porcentaje = convert(float,dc_valor)
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 6

   /*ESPECIAL*/
   select @w_reaj_especial = dc_valor
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 7 

   /*DESAGIO*/   

   select @w_desagio = dc_valor
   from   ca_decodificador
   where  dc_operacion = @i_operacion
   and    dc_user      = @s_user
   and    dc_sesn      = @s_sesn
   and    dc_fila      = @w_fila
   and    dc_columna   = 8 


   exec @w_return = sp_insertar_reajustes
   @s_date            = @s_date,
   @s_ofi             = @s_ofi,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @i_banco           = @w_banco,
   @i_especial        = @w_reaj_especial,
   @i_fecha_reajuste  = @w_fecha,
   @i_concepto        = @i_concepto,
   @i_referencial     = @w_referencial, 
   @i_signo           = @w_signo,
   @i_factor          = @w_factor,
   @i_porcentaje      = @w_porcentaje,
   @i_desagio	      = @w_desagio	

   if @w_return <> 0 return  @w_return

   select @w_fila = @w_fila +1


   delete ca_secasunto
   where se_operacion = @w_operacionca
   and   se_fecha_reajuste = @w_fecha
   and   se_estado = 'N'
   

   insert into ca_secasunto 
   (se_secuencial,  se_operacion,   se_banco, se_fecha_reajuste, se_estado)
   values 
   (@w_secuencial,  @w_operacionca, @w_banco, @w_fecha,          'N')
   if @@error <> 0
   begin
      print 'error en insercion en ca_secasunto..leereaju.sp..'
   end    

   update ca_reajuste
   set   re_sec_aviso = @w_secuencial
   from  ca_reajuste
   where re_operacion = @w_operacionca
   and   re_fecha     = @w_fecha
   if @@error <> 0
   begin
      print 'error en update ca_reajuste, leereaju.sp..'
   end    

      
   
   

end /*end while*/


delete ca_decodificador
where dc_operacion = @i_operacion
and   dc_user      = @s_user
and   dc_sesn      = @s_sesn

---NR-684
   select @w_cargadas = count(1)
   from ca_reajuste
   where  re_sec_aviso = @w_secuencial
   
   PRINT '!!! ATENCION REAJUSTE MASIVOS..Reajustes Cargados: ' + cast(@w_cargadas as varchar)
   

return 0

go

