/************************************************************************/
/*   Archivo:                 paramplanif.sp                            */
/*   Stored procedure:        sp_rubro_planificador                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  Mar-2007                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */ 
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                 PROPOSITO                            */
/*   Dar mantenimiento a la tabla ca_rubro_planificador  forma          */
/*   FRUBROPLANIF.FRM                                                   */
/*                               MODIFICACIONES                         */
/*  FECHA            AUTOR             RAZON                            */
/*                                                                      */
/************************************************************************/

use cob_cartera

go

if exists (select 1 from cob_cartera..sysobjects where name = 'sp_rubro_planificador ')
   drop proc sp_rubro_planificador 
go

create proc sp_rubro_planificador 
   @s_user                   login,
   @s_date                   datetime,
   @t_trn                    int          = 0,
   @s_sesn                   int          = 0,
   @s_term                   varchar (30) = NULL,
   @s_ssn                    int          = 0,
   @s_srv                    varchar (30) = null,
   @s_lsrv                   varchar (30) = null,
   @i_operacion              char(1),
   @i_rubro                  catalogo     = null,
   @i_porcentaje_cobrar      float        = null,
   @i_concepto_sidac         catalogo     = null,
   @i_secuencial             int          = null


as

declare 
   @w_sp_name                 varchar(20),
   @w_sec                     int,
   @w_error                   int

select @w_sp_name = 'sp_rubro_planificador ',
       @w_sec = 0


    
 
if @i_operacion = 'S' 
begin
  select 
     'Sec.'        = rp_secuencial,
     'RUBRO      ' = rp_rubro,
     'DES.RUBRO  ' = co_descripcion,
     '% DE PAGO  ' = rp_porcentaje,
     'CONC.SIDAC ' = rp_cto_sidac 
  from  ca_rubro_planificador,
        ca_concepto
  where co_concepto = rp_rubro
  order by rp_secuencial

   
end 

if @i_operacion = 'I' 
begin
   if not exists 
   (select 1 from cobis..cl_catalogo
                             where tabla = ( select codigo
                                            from cobis..cl_tabla
                                            where tabla = 'ac_conceptos_cxp')
    and codigo = @i_concepto_sidac
                                            )
      begin
        select @w_error =  720701
        goto ERROR
      end
                                            
                                            
   
   
   select @w_sec = isnull(max(rp_secuencial),1)
   from ca_rubro_planificador
   
   select @w_sec = @w_sec + 1
   
   if exists (select 1 from ca_rubro_planificador
              where rp_rubro = @i_rubro)

      begin
        select @w_error =  720702
        goto ERROR
      end              
              
   insert into ca_rubro_planificador
            (rp_secuencial,   rp_rubro,   rp_porcentaje,   rp_cto_sidac)
            values
            (@w_sec,   @i_rubro,   @i_porcentaje_cobrar,   @i_concepto_sidac)

      if @@error <> 0
      begin
         select @w_error = 720703 
         goto ERROR
      end            
            

end 

if @i_operacion = 'D' ---Delete
begin
   
   delete ca_rubro_planificador
   where rp_secuencial = @i_secuencial
   and   rp_rubro = @i_rubro
   if @@error <> 0
   begin
      select @w_error = 720704
      goto ERROR
   end            
   

end 

if @i_operacion = 'U' ---Delete
begin
   
   Update ca_rubro_planificador
   set rp_rubro      = @i_rubro,
       rp_porcentaje =  @i_porcentaje_cobrar,
       rp_cto_sidac  =  @i_concepto_sidac
   where rp_secuencial = @i_secuencial
   if @@error <> 0
   begin
      select @w_error = 720704
      goto ERROR
   end            
   

end 

if @i_operacion in ('D','I','U')
begin
   
   if @w_sec = 0
      select @w_sec= @i_secuencial
      
   insert into ca_rubro_planificador_ts
     (rps_secuencial,    rps_rubro,    rps_porcentaje,    rps_cto_sidac,     rps_usuario,    
      rps_terminal,      rps_fecha,         rps_accion)     
   values
     (@w_sec,           @i_rubro,   @i_porcentaje_cobrar,   @i_concepto_sidac,  @s_user,
     @s_term,           getdate(),  @i_operacion
     )

   if @@error <> 0
   begin
      select @w_error = 720705
      goto ERROR
   end            
end


return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',    
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return     @w_error
go

