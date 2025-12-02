/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           ElciraPelaezBurbano                     */
/*      Fecha de escritura:     Sep 2011                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Recibe unarchivo plano para caragr datos que seran eliminados   */
/*      de la tabla cob_credito..cr_cliente_campana  batch 7121         */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

IF exists (SELECT  1 FROM sysobjects WHERE name = 'ca_elim_cliente_COfertas_tmp')
   drop table ca_elim_cliente_COfertas_tmp 
go

CREATE TABLE dbo.ca_elim_cliente_COfertas_tmp 
(
    el_oficina          int      NOT NULL,
    el_tipo_ced         char(2)  NOT NULL, 
    el_ced_ruc          numero   NOT NULL,
    el_campana          int      NULL
)
go

if exists (select 1 from sysobjects where name = 'sp_elim_cliente_COfertas') 
drop proc sp_elim_cliente_COfertas
go


create proc sp_elim_cliente_COfertas 
   

as 
declare 
@w_path       varchar(250),
@w_cmd        varchar(250),
@w_s_app      varchar(250),
@w_destino    varchar(250),
@w_errores    varchar(250),
@w_comando    varchar(300),
@w_error      int

      
-- CARGA DEL ARCHIVO ENTREGADO POR BANCAMIA

truncate table ca_elim_cliente_COfertas_tmp
     

select @w_s_app   = pa_char from cobis..cl_parametro where pa_producto = 'ADM' and   pa_nemonico = 'S_APP'

select @w_path = pp_path_destino
from cobis..ba_path_pro  
where pp_producto = 7

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_elim_cliente_COfertas_tmp in '
select @w_destino = @w_path + 'ca_elim_cliente_COfertas_tmp' + '.txt', @w_errores  = @w_path + 'ca_elim_cliente_COfertas_tmp' + '.err'
select @w_comando = @w_cmd + @w_path + 'ca_elim_cliente_COfertas_tmp.txt -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

print @w_comando

exec   @w_error   = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Cargando Archivo Eliminacion Clientes Contra Ofertas'
   return 0
end

delete cob_credito..cr_cliente_campana
from  cob_credito..cr_cliente_campana,cob_cartera..ca_elim_cliente_COfertas_tmp
where cc_cliente in (select en_ente 
                      from cob_cartera..ca_elim_cliente_COfertas_tmp, 
                           cobis..cl_ente with (nolock)
                      where el_ced_ruc = en_ced_ruc)
and el_oficina = cc_oficina
and el_campana = cc_campana

                     


return 0
go
