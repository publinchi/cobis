/* **********************************************************************/
/*      Archivo           : generar_curp.sp                             */
/*      Stored procedure  : sp_generar_curp                             */
/*      Base de datos     : cobis                                       */
/*      Producto:               Clientes                                */
/*      Disenado por:           JMEG                                    */
/*      Fecha de escritura:     30-Abril-19                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Permite calcular el CURP y RFC (mexico)                             */
/* **********************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19        JMEG            Emision Inicial                 */
/*      17/06/20        MBA             Estandarizacion sp y seguridades*/
/*      15/10/20        MBA             Uso de la variable @s_culture   */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_generar_curp')
   drop procedure sp_generar_curp
go

create procedure sp_generar_curp(
	@s_culture              varchar(10) = 'NEUTRAL',
    @t_debug                char(1)     = 'N',
    @t_file                 varchar(10) = null,
    @t_from                 varchar(32) = null,
	@t_show_version         bit         = 0,
    @i_primer_apellido      varchar(100),
    @i_segundo_apellido     varchar(100),
    @i_nombres              varchar(100),
    @i_sexo                 varchar(10),
    @i_fecha_nacimiento     datetime,
    @i_entidad_nacimiento   int,
    @o_mensaje              varchar(100) = null output,
    @o_curp                 varchar(30) = null output,
    @o_rfc                  varchar(30) = null output)
as
declare
    @w_sp_name          varchar(30),
	@w_sp_msg           varchar(132),
    @w_alfa             varchar(30),
    @w_curp             varchar(30),
    @w_pos              smallint,
    @i_nombres_aux      varchar(100),
    @w_apellido_aux     varchar(100),
    @w_entidad_aux      varchar(10),
    @w_p_apellido_aux   varchar(100),
    @w_s_apellido_aux   varchar(100),
    @w_anio             char,
    @w_fecha_nac        varchar(10)


/* captura nombre de stored procedure  */
select @w_sp_name = 'cobis..sp_generar_curp'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		

    -- caracteres alfabeticos permitidos
   select @w_alfa = '%[^A-ZÑ0-9]%'

   select
        @i_primer_apellido  = upper(rtrim(ltrim( isnull(@i_primer_apellido,'') ))),
        @i_segundo_apellido = upper(rtrim(ltrim( isnull(@i_segundo_apellido,'') ))),
        @i_nombres          = upper(rtrim(ltrim( isnull(@i_nombres,'')))),
        @i_sexo             = upper(rtrim(ltrim( @i_sexo)))

    select
        @i_primer_apellido     = cobis.dbo.fn_filtra_acentos(@i_primer_apellido ),
        @i_segundo_apellido    = cobis.dbo.fn_filtra_acentos(@i_segundo_apellido ),
        @i_nombres             = cobis.dbo.fn_filtra_acentos(@i_nombres )

    if (@i_sexo = 'M') select @i_sexo = 'H' else select @i_sexo = 'M'

--/////////////////////////////////////
   select
        @w_p_apellido_aux  = @i_primer_apellido,
        @w_s_apellido_aux  = @i_segundo_apellido,
        @i_nombres_aux     = @i_nombres


    select @i_nombres          = cobis.dbo.fn_filtra_nombres(@i_nombres)
    select @i_primer_apellido  = cobis.dbo.fn_filtra_nombres(@i_primer_apellido)
    select @i_segundo_apellido = cobis.dbo.fn_filtra_nombres(@i_segundo_apellido)


    --// validar que los datos estan correctors
    if  (@i_primer_apellido = '')
    begin
        select @o_mensaje = 'Primer apellido es obligatorio'
        return 1
    end
    if (@i_primer_apellido like @w_alfa)
    begin
        select @o_mensaje = 'Primer apellido no valido, caracteres validos: A-Z (incluso Ñ)'
        return 2
    end

    if (@i_segundo_apellido <> '' and @i_segundo_apellido like @w_alfa)
    begin
        select @o_mensaje = 'Segundo apellido no valido, caracteres validos: A-Z (incluso Ñ)'
        return 4
    end
    if (@i_nombres = '')
    begin
        select @o_mensaje = 'Nombre(s) es obligatorio'
        return 5
    end
    if (@i_nombres like @w_alfa)
    begin
        select @o_mensaje = 'Nombre(s) no valido, caracteres validos: A-Z (incluso Ñ)'
        return 6
    end

    if (@i_sexo not in ('H', 'M'))
    begin
        select @o_mensaje = 'Sexo no valido'
        return 7
    end

    if (@i_fecha_nacimiento is null)
    begin
        select @o_mensaje = 'Fecha de nacimiento no valido'
        return 8
    end

    if (@i_entidad_nacimiento = 0)
    begin
        select @o_mensaje = 'Entidad de nacimiento es obligatorio'
        return 9
    end


    select  @w_entidad_aux = e2.eq_valor_arch
    from cob_conta_super..sb_equivalencias e1, cob_conta_super..sb_equivalencias e2
    where e1.eq_catalogo = 'ENT_FED'
    and e1.eq_valor_cat = convert(varchar, @i_entidad_nacimiento)
    and e2.eq_catalogo = 'ENT_CURP'
    and e2.eq_valor_cat = e1.eq_valor_arch

    select @w_entidad_aux = isnull(@w_entidad_aux ,'') --abu cambio por defecto
    if (@w_entidad_aux = '')
    begin
        select @o_mensaje = 'No existe Entidad de nacimiento'
        return 1720329
    end


    select @w_fecha_nac = substring(convert(varchar,@i_fecha_nacimiento,101),9,2) + -- anio
                          substring(convert(varchar,@i_fecha_nacimiento,101),1,2) + -- mes
                          substring(convert(varchar,@i_fecha_nacimiento,101),4,2)   -- dia

    if (len(@i_segundo_apellido) = 0)
        select @o_rfc = substring(@i_primer_apellido, 1,2) + substring(@i_nombres, 1,2)
    else
    if (len(@i_primer_apellido) < 3)
        select @o_rfc = substring(@i_primer_apellido, 1,2) +  substring(@i_segundo_apellido, 1,1) + substring(@i_nombres, 1,2)
    else
        select @o_rfc = substring(@i_primer_apellido, 1,1) +
                        cobis.dbo.fn_primera_letra(substring(@i_primer_apellido,2,100),'V'  ) + -- primera vocal
                        substring(@i_segundo_apellido, 1,1) + substring(@i_nombres, 1,1)
    select @o_rfc = cobis.dbo.fn_altisonante('rfc',@o_rfc)
    
    select @o_rfc = @o_rfc + @w_fecha_nac

    -----------------
    --// rfc final
    -----------------
    select @o_rfc = @o_rfc + cobis.dbo.fn_homoclave_rfc (@i_nombres_aux, @w_p_apellido_aux, @w_s_apellido_aux)
    select @o_rfc = @o_rfc + cobis.dbo.fn_digito_rfc (@o_rfc)

     

    -- generar el CURP
    --/////////////////////////////////////////////////////
    select @w_curp = substring(@i_primer_apellido,1,1) +                                       -- 1ra letra apellido 1
                     cobis.dbo.fn_primera_letra( substring(@i_primer_apellido   ,2,100),'V')   -- 1ra vocal apellido 1
                     
    if (len(@i_segundo_apellido) <= 0)
        select @w_curp = @w_curp + 'X'
    else
        select @w_curp = @w_curp + substring(@i_segundo_apellido,1,1)  -- 1ra letra apellido 2

    select @w_curp = @w_curp + substring(@i_nombres,1,1)  -- 1ra letra del nombre
    select @w_curp = @w_curp + @w_fecha_nac


    select @w_curp = @w_curp + @i_sexo
    select @w_curp = @w_curp + @w_entidad_aux
    
    select @w_curp = @w_curp + cobis.dbo.fn_primera_letra( substring(@i_primer_apellido,2,100),'C')  -- primera consonante
    
    if (len(@i_segundo_apellido) <= 0)
        select @w_curp = @w_curp + 'X'
    else
        select @w_curp = @w_curp + cobis.dbo.fn_primera_letra( substring(@i_segundo_apellido   ,2,100),'C')     -- primera consonante

    select @w_curp = @w_curp + cobis.dbo.fn_primera_letra( substring(@i_nombres        ,2,100),'C')          -- primera consonante

    if convert(int,substring(convert(varchar,@i_fecha_nacimiento,101),7,4)) < 2000 select @w_anio = '0' else select @w_anio = 'A'

    -----------------
    -- // curp final
    -----------------
    select @w_curp = @w_curp + @w_anio
    -- filtrar altisonantes CURP
    select @w_curp = cobis.dbo.fn_altisonante('CURP',@w_curp)
    select @o_curp = @w_curp + cobis.dbo.fn_digito_curp (@w_curp)

    -- solo en caso de que no haya generado 18 caracteres, para identificar como error
    select @o_curp = replicate('X',18-len(@o_curp)) + @o_curp
   
    return 0


GO

