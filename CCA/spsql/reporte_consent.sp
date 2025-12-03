/************************************************************************/
/*   Archivo:              reporte_consent.sp                           */
/*   Stored procedure:     sp_reporte_consentimiento                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Alexander Orbes                              */
/*   Fecha de escritura:   Julio 12-2019                                */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Consulta los datos para el Reporte de Consentimiento de Programa   */
/*   de prevención                                                      */
/*   LAS OPERACIONES MANEJADAS SON:                                     */
/*                                                                      */
/*   'S'     Consulta los datos del titular y beneficiarios             */
/*                                                                      */
/*   MODIFICACIONES                                                     */
/* Fecha            Autor                         Observaciones     */
/* 07/01/2020   Gerardo Barron           Correccion en la obtencion de los beneficiarios */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_reporte_consentimiento')
   drop proc sp_reporte_consentimiento
go

create proc sp_reporte_consentimiento
   @s_ofi               smallint    = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               int         = null,
   @i_operacion         int
   as 
   declare
   @w_sp_name                      varchar(32),
   @w_tramite						int,
   @o_impresiones                  int,
   @w_filial_1							varchar(100),
   @w_filial_2							varchar(100),
   @w_sitio_web							varchar(100),
   @w_dir_filial						varchar(200)
   
   -- CAPTURA NOMBRE DE STORED PROCEDURE
   select   @w_sp_name = 'sp_reporte_consentimiento'

   
   exec cobis..sp_cseqnos
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_tabla = 'cr_imp_doc',
   @o_siguiente = @o_impresiones out
   
   begin
   
   
   --Se obtiene la filial
	select @w_filial_1 = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 9
	
	--Se obtiene la filial 2
	select @w_filial_2 = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 10
	
	--Se obtiene la direccion de la filial
	select @w_dir_filial = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 1
	
	--Se obtiene el sitio web 
	select 	@w_sitio_web = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 5

   
   select op_cliente,
   op_banco,
   (select of_nombre 
   from cobis..cl_oficina 
   where of_oficina = op_oficina),
   isnull(@o_impresiones,0),
   (select max(so_fecha_fin) from cob_cartera..ca_seguros_op where 
   so_operacion=@i_operacion),
   concat(en_nombre,' ',p_s_nombre),
   p_p_apellido,
   p_s_apellido,
   p_fecha_nac,
   'subsidiary1' = @w_filial_1,
   'subsidiary2' = @w_filial_2,
   'subsidiaryAddress' = @w_dir_filial,
   'webSite'=@w_sitio_web
   
   from cobis..cl_ente, 
   cob_cartera..ca_operacion WHERE
   en_ente=op_cliente and
   op_operacion=@i_operacion
   
   select so_tipo_seguro from cob_cartera..ca_seguros_op where
   so_operacion=@i_operacion
   
   select @w_tramite = op_tramite
   from cob_cartera..ca_operacion
   where op_operacion = @i_operacion
   
   select concat(bs_apellido_paterno ,' ', bs_apellido_materno,' ',  bs_nombres),
  (select c.valor FROM cobis..cl_tabla t ,cobis..cl_catalogo c 
   where t.tabla='cl_parentesco_beneficiario' and 
   t.codigo=c.tabla
   and c.codigo =bs_parentesco),
   bs_porcentaje
   from cobis..cl_beneficiario_seguro where bs_tramite = @w_tramite
   and bs_producto=(select pd_producto FROM cobis..cl_producto where pd_abreviatura='CCA')
   end
   
   
   return 0
   go
   