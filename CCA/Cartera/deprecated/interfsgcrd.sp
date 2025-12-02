/******************************************************************/
/*  Archivo:            interfsgcrd.sp                            */
/*  Stored procedure:   sp_seguros_credito_srv                    */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Jonathan Tomala                           */
/*  Fecha de escritura: 18-Jul-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Manejo de reglas                                           */
/*   - Creacion de Seguros                                        */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  18/Jul/19     Jonathan Tomala  Creacion sp_seguros_credito_srv*/
/*  24/ENE/2020   Armando Miramón  Se ajustan consultas y formato */
/*                                 de fecha                       */
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_seguros_credito_srv')
   drop proc sp_seguros_credito_srv
go

create proc sp_seguros_credito_srv
   @s_user                  login        = null,
   @s_term                  varchar(30)  = null,
   @s_srv                   varchar(30)  = null,
   @s_date                  datetime     = null,
   @s_sesn                  int          = null,
   @s_ssn                   int          = null,
   @s_ofi                   smallint     = null,
   @s_rol                   smallint     = null,
   @t_trn                   int          = 77517,
   @i_interfaz              char(1)      = null,
   @i_banco                 cuenta       = null,   -- Se envia desde la pantalla datos operacion de CCA
   @i_formato_fecha         tinyint      = 103,
   @o_resultado             int          = 0    out,
   @o_msg_resultado         varchar(132) = null out
as declare
@w_sp_name                varchar(30),
@w_error                  int


select @o_resultado = 0, @o_msg_resultado = null  -- POR DEFECTO

-- VALIDA QUE EXISTA LA OPERACION
if not exists (select 1 from cob_cartera..ca_operacion where op_banco = @i_banco)
begin
    select @w_error = 141183 -- No existe la operacion de cartera
    --goto ERROR
end

-- CONSULTA DATOS DE SEGURO
select 'NRO CREDITO'      = op_ref_grupal,
    'CLIENTE'          = so_cliente,
    'TIPO SEGURO'      = so_tipo_seguro,
    --'TIPO SEGURO'      = a.valor,
    'FOLIO'            = so_folio,
    'MONTO'            = so_monto_seguro,
    'FECHA VIG INI'    = convert(varchar(10),so_fecha_inicial,@i_formato_fecha),
    'FECHA VIG FIN'    = convert(varchar(10),isnull(so_fecha_fin, op_fecha_fin),@i_formato_fecha),
    'ESTADO'           = so_estado
from ca_operacion inner join ca_seguros_op
    on so_operacion = op_operacion --inner join cobis..cl_catalogo as a
    --on a.codigo = so_tipo_seguro inner join cobis..cl_tabla as b
    --on b.codigo = a.tabla and b.tabla = 'ca_tipo_seguro'
where op_banco = @i_banco or op_ref_grupal = @i_banco

IF @@ROWCOUNT = 0
begin
    select @w_error = 601153 -- No existen registros para la consulta dada
    --goto ERROR
end

-- OPERACION DE DESCOMPRIMIR LA DIRECCION
-- FORMATO DE DIRECCION:   CALLE | NUMERO EXTERIOR | NUMERO INTERIOR
;WITH BeneficiariosSeguros as (
select bs_nro_operacion,
    op_cliente,
    bs_nombres,
    bs_apellido_paterno,
    bs_apellido_materno,
    bs_fecha_nac,
    bs_parentesco,
    bs_porcentaje,
    bs_codpostal,
    bs_parroquia,
    bs_telefono,
    bs_secuencia,
    NumeroColumna = ROW_NUMBER() OVER(PARTITION BY bs_nro_operacion ORDER BY (SELECT NULL)),
    value
from ca_operacion inner join cobis..cl_beneficiario_seguro 
    cross apply STRING_SPLIT(bs_direccion, '|') as BS
    on bs_nro_operacion = op_operacion 
where op_banco = @i_banco or op_ref_grupal = @i_banco
)
--CONSULTA DATOS DE BENEFICIARIO
select 'CLIENTE' = op_cliente,
    'SECUENCIA' = bs_secuencia,
    'CAPELLIDOS' = bs_apellido_materno,
    'CAPELLIDOP' = bs_apellido_paterno,
    'CNOMBRE' = bs_nombres,
    'FECHA NAC.' = convert(varchar(10),bs_fecha_nac,@i_formato_fecha),
    'PARENTESCO' = bs_parentesco, 
    'PORCENTAJE' = bs_porcentaje,
    'CALLE' = [1],
    'NUM EXT' = [2],
    'NUM INT' = [3],
    'CCODPOSTAL' = bs_codpostal,
    'CCOLONIA' = bs_parroquia,
    'TELEFONO' = bs_telefono
from BeneficiariosSeguros
pivot(
    MAX(value) 
    for NumeroColumna in ([1], [2], [3])
) as PvtBS

if @w_error > 0
begin
   goto ERROR
end

return 0

ERROR:
    /*exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error*/

   SELECT @o_resultado = numero, @o_msg_resultado = mensaje FROM cobis..cl_errores WHERE numero = @w_error

   return @w_error
go