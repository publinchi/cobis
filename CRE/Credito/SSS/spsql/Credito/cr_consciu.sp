/************************************************************************/
/*        Archivo:                cr_consciu.sp                         */
/*        Stored procedure:       sp_consulta_ciudad                    */
/*        Base de Datos:          cob_credito                           */
/*        Producto:               Credito                               */
/*        Disenado por:           Maria Jose Taco                       */
/*        Fecha de Documentacion: 23/Nov/2016                           */
/********************************************************************** */
/*                        IMPORTANTE                                    */
/*        Este programa es parte de los paquetes bancarios propiedad de */
/*        'COBISCORP',representantes exclusivos para el Ecuador de la   */
/*        AT&T                                                          */
/*        Su uso no autorizado queda expresamente prohibido asi como    */
/*        cualquier autorizacion o agregado hecho por alguno de sus     */
/*        usuario sin el debido consentimiento por     escrito de la    */
/*        Presidencia Ejecutiva de COBISCORP o su representante         */
/********************************************************************** */
/*                        PROPOSITO                                     */
/*        Realiza la consulta de la ciudad de la oficina del tramite    */
/********************************************************************** */
/*                        MODIFICACIONES                                */
/*        FECHA                AUTor          RAZON                     */
/*        27/Jul/95        Maria Jose Taco    Emision Inicial           */
/************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_consulta_ciudad')
    drop proc sp_consulta_ciudad
go


CREATE PROCEDURE sp_consulta_ciudad (
    @s_ssn           int          = null, 
    @s_user          varchar(30)  = null,
    @s_sesn          int          = null,
    @s_term          varchar(30)  = null,
    @s_date          datetime     = null,    
    @i_oficina       int          = null    
)
as
declare
   @w_sp_name           varchar(32),
   @w_ciudad            descripcion,
   @w_codigo            char(10),
   @w_cod_ciudad        int


select @w_sp_name = 'sp_consulta_ciudad'

select @w_cod_ciudad = of_ciudad
  from cobis..cl_oficina
 where of_oficina = @i_oficina


select @w_codigo = c.codigo,
       @w_ciudad = c.valor
  from cobis..cl_tabla t, cobis..cl_catalogo c 
 where c.tabla  = t.codigo 
   and c.codigo = convert(varchar(10), @w_cod_ciudad )
   and t.tabla  = 'cl_ciudad' 

if @w_codigo is null
begin
 --'No existe ciudad'
 exec cobis..sp_cerror
    @t_from	 = @w_sp_name,
    @i_num	 = 101024
 return 1
end

select  @w_cod_ciudad=  convert(int,@w_codigo  )

select  @w_cod_ciudad
select  @w_ciudad

return 0  

GO

