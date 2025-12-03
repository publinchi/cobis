

/********************************************************************/
/*    NOMBRE LOGICO: fn_homologa_fec                                */
/*    NOMBRE FISICO: fn_homologa_fec.sp                             */
/*    PRODUCTO: Clientes                                            */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.".         */
/********************************************************************/
/*                           PROPOSITO                              */
/*  Función para homologar catálogos de facturación electrónica     */
/*  de Cobis VS Ricoh                                               */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR            RAZON                       */
/*  04-MAY-2023        G. Chulde        Emisión inicial             */
/********************************************************************/
use cob_externos
go

if exists (select 1
             from sysobjects
            where id = object_id('fn_homologa_fec'))
   drop function fn_homologa_fec

go

create function fn_homologa_fec (@i_tab_cobis varchar(64), @i_val_cobis varchar(10))
returns varchar(10) AS
begin
	declare 
	@w_val_homologado   varchar(10) = null,
	@w_tab_homologacion varchar(64),
	@w_id_tab_hom       int
	
	select @w_tab_homologacion = @i_tab_cobis + '_fec'
	
	select @w_id_tab_hom = codigo from cobis..cl_tabla where tabla = @w_tab_homologacion
	
	select @w_val_homologado = valor from cobis..cl_catalogo where tabla = @w_id_tab_hom and codigo = @i_val_cobis
	
	if isnull(@w_val_homologado,'') = ''
	begin
		select @w_val_homologado = 'NE'
	end	
	
    return @w_val_homologado
end
go
