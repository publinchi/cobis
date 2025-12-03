/********************************************************************/
/*    NOMBRE LOGICO:         sp_guid_fe                             */
/*    NOMBRE FISICO:         sp_guid_fe.sp                          */
/*    PRODUCTO:              Facturacion Electronica                */
/*    Disenado por:          Armando Quishpe                        */
/*    Fecha de escritura:    20-Abril-2023                          */
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
/* Sp que permite crear un guid para la facturacion electronica     */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  20-Abr-2023      A. Quishpe       Emision Inicial               */
/********************************************************************/

USE cob_externos
GO

if object_id('sp_guid_fe') is not null
begin
      drop procedure sp_guid_fe
end
go

create proc sp_guid_fe(
       @t_show_version       bit          = 0,
	   @o_guid               CHAR(36)     = '' OUT
)

as
declare @w_sp_name     varchar(30),
        @w_cadena      varchar(36)

select @w_sp_name    = 'sp_guid_fe'

if @t_show_version = 1
begin
    print 'Versión: sp_guid_fe: 5.0.0.1 '
    return 0
end

SELECT @w_cadena = newid()
SELECT @o_guid = @w_cadena


return 0
go
