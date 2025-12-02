USE cob_interface
GO
/************************************************************/
/*   ARCHIVO:         sp_val_solicitud_linea_int.sp         */
/*   NOMBRE LOGICO:   sp_val_solicitud_linea_int            */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Validar parametros de entrada de una solicitud de      */
/*   apertura de linea de credito.                          */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 21/SEP/2021     EBA              Emision Inicial         */
/* 24/MAR/2022     pmoreno          Validacion fecha proceso*/
/* 11/AGO/2022     bduenas          R191496 - Validacion del*/
/*                                  oficial                 */
/************************************************************/

if exists(select 1 from sysobjects where name ='sp_val_solicitud_linea_int')
    drop proc sp_val_solicitud_linea_int
go

create procedure sp_val_solicitud_linea_int
(
        @t_debug              char(1)      = 'N',
        @t_file               varchar(14)  = null,
      @t_from                 varchar(30)  = null,
      @i_sector               catalogo     = null,
      @i_num_dias             smallint      = 0,
        @i_oficial            smallint,
        @i_oficina            smallint,
        @i_ciudad             int,
      @i_moneda               tinyint,
      @i_toperacion           catalogo,
      @i_origen_fondos        catalogo,
      @i_cliente              int,
      @i_rotativo             char(1),
      @i_fecha_ini            datetime       = null
)
as
declare
       @w_error                  int,
       @w_sp_name                varchar(32),
       @w_sector                 catalogo,
       @w_destino                catalogo,
       @w_origen                 catalogo,
       @w_ente                   int,
       @w_moneda                 int,
       @w_fecha                  datetime

select @w_sp_name = 'sp_val_solicitud_linea_int',
       @w_error   = 0
      
-- Fecha
select @w_fecha = fp_fecha from cobis..ba_fecha_proceso

if @i_fecha_ini = null
begin
   select @i_fecha_ini = @w_fecha
end

if (@i_fecha_ini < @w_fecha)
begin
   select @w_error = 708142
    goto SALIR
end

-- Oficina
if not exists (select 1 
               from   cobis..cl_oficina 
               where  of_oficina = @i_oficina)
begin
   select @w_error = 2110151
   goto SALIR
end

-- Sector
if (@i_sector is not null)
begin
   select @w_sector = c.valor
     from cobis..cl_tabla t,
          cobis..cl_catalogo c
    where t.tabla  = 'cc_sector'
      and t.codigo = c.tabla
      and c.codigo = @i_sector
   if @@rowcount = 0
   begin 
      select @w_error = 2110126
      goto SALIR
   end
end

-- Ciudad
select @w_destino = c.valor
  from cobis..cl_tabla t,
       cobis..cl_catalogo c
 where t.tabla  = 'cl_ciudad'
   and t.codigo = c.tabla
   and c.codigo = @i_ciudad
if @@rowcount = 0
begin 
   select @w_error = 2110206
   goto SALIR
end

-- Oficial
if not exists(select 1
              from cobis..cl_funcionario, 
                   cobis..cc_oficial, 
                   cobis..ad_usuario
              where fu_funcionario = oc_funcionario
              and   oc_oficial     = @i_oficial
              and   us_oficina     = @i_oficina
              and   us_login       = fu_login)
begin
   select @w_error = 2110145
   goto SALIR
end    

-- Moneda
select @w_moneda = dl_moneda 
from   cob_credito..cr_datos_linea
where  dl_toperacion = @i_toperacion
and    dl_moneda     = @i_moneda

if @@rowcount = 0
begin 
   select @w_error = 2110147
   goto SALIR
end

-- Origen de fondos
select @w_origen = c.valor
  from cobis..cl_tabla t,
       cobis..cl_catalogo c
 where t.tabla  = 'cr_origen_fondo'
   and t.codigo = c.tabla
   and c.codigo = @i_origen_fondos
if @@rowcount = 0
begin 
   select @w_error = 2110143
   goto SALIR
end

--Deudor principal
if @i_cliente is null
begin
   select @w_error = 2110207 --El deudor principal no puede ser nulo o 0
   goto SALIR
end

select @w_ente = en_ente 
from   cobis..cl_ente
where  en_ente = @i_cliente

if @@rowcount = 0
begin 
   select @w_error = 2110208 -- El cliente no existe
   goto SALIR
end

--Rotativo
if @i_rotativo not in ('N', 'S')
begin
   select @w_error = 2110209 -- El valor de rotativo solo puede ser S o N
   goto SALIR
end

return 0

SALIR:
return @w_error
go
