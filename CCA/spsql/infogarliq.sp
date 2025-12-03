/************************************************************************/ 
/*      Archivo:                infogarliq.sp                           */ 
/*      Stored procedure:       sp_cons_info_garliq                     */
/*      Base de datos:          cob_cartera                             */ 
/*      Producto:               Cartera                                 */ 
/*      Disenado por:           T Baidal                                */ 
/*      Fecha de escritura:     Ago 2017                                */ 
/************************************************************************/ 
/*                              IMPORTANTE                              */ 
/*      Este programa es parte de los paquetes bancarios propiedad de   */ 
/*      'MACOSA'.                                                       */ 
/*      Su uso no autorizado queda expresamente prohibido asi como      */ 
/*      cualquier alteracion o agregado hecho por alguno de sus         */ 
/*      usuarios sin el debido consentimiento por escrito de la         */ 
/*      Presidencia Ejecutiva de MACOSA o su representante.             */ 
/************************************************************************/ 
/*                              PROPOSITO                               */ 
/* Procedimiento que consulta información de garantía líquida           */    
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */ 
/*   21/Ago/2017   T. Baidal      Emision Inicial                       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cons_info_garliq')
   drop proc sp_cons_info_garliq
go 

create proc sp_cons_info_garliq
@s_ssn                       int         = NULL, 
@s_sesn                      int         = NULL,
@s_term                      varchar(30) = NULL,
@s_user                      login       = NULL, 
@s_date                      datetime    = NULL, 
@s_srv                       varchar(30) = NULL,
@s_lsrv                      varchar(30) = null, 
@s_org                       char(1)     = null,      
@s_ofi                       smallint    = NULL,
@s_rol                       int         = 1,
@t_ssn_corr                  int         = NULL,
@i_tramite                   int

as 

declare
@w_sp_name      varchar(20),
@w_error        int

select @w_sp_name = 'sp_cons_info_garliq'

select
grupo_id      = in_grupo_id, 
nombre_grupo  = in_nombre_grupo, 
fecha_proceso = in_fecha_proceso,
fecha_liq     = in_fecha_liq,    
fecha_venc    = in_fecha_venc,  
moneda        = in_moneda,      
num_pago      = in_num_pago,    
monto         = in_monto,        
institucion   = in_institucion ,
referencia    = in_referencia  ,
dest_nombre1  = in_dest_nombre1,
dest_cargo1   = in_dest_cargo1 , 
dest_email1   = in_dest_email1 ,  
dest_nombre2  = in_dest_nombre2,  
dest_cargo2   = in_dest_cargo2 , 
dest_email2   = in_dest_email2 ,
dest_nombre3  = in_dest_nombre3, 
dest_cargo3   = in_dest_cargo3 , 
dest_email3   = in_dest_email3 ,  
of_nombre
from cob_cartera..ca_infogaragrupo, cobis..cl_oficina
where in_oficina_id = of_oficina
and in_tramite = @i_tramite

if @@rowcount = 0
begin
   select @w_error = 70130 --ERROR AL CONSULTAR DATOS DEL TRÁMITE
   goto ERROR
end

return 0


ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error

go