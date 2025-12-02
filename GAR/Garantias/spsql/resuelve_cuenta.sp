/****************************************************************/
/* ARCHIVO:              resuelve_cuenta.sp                     */
/* Stored procedure:	 sp_resuelve_cuenta	          	        */
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_resuelve_cuenta') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_resuelve_cuenta
    IF OBJECT_ID('dbo.sp_resuelve_cuenta') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_resuelve_cuenta >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_resuelve_cuenta >>>'
END
go
create proc dbo.sp_resuelve_cuenta
        @i_filial          int,
        @i_moneda          smallint,
        @i_tipo_custodia   catalogo,  
        @i_tipo_cca        catalogo,  --LGU  10.04.2002
        @i_cuenta          varchar(20),
	@i_sector_conta    catalogo = null,	--TRugel 02/12/2007
        @o_cuenta_final    varchar(20) out,
        @o_error           varchar(255) out
as
declare 
@w_sp_name          descripcion,
@w_cuenta           varchar(20),
@w_pos              smallint,
@w_trama            varchar(20),
@w_ascii            int,
@w_contenido_trama  int,
@w_resultado        varchar(20),
@w_error            char(1),
@w_variable         varchar(20)



-- INICIALIZACION DE VARIABLES
select @w_cuenta  = @i_cuenta,
       @o_error   = '',
       @w_sp_name = 'sp_revuelve_cuenta'


select @w_pos    = charindex('.',@w_cuenta)

-- LAZO DE RESOLUCION
while 0 = 0 
 begin
   -- ELIMINAR PUNTOS INICIALES 
   while @w_pos = 1 
   begin
       select @w_cuenta = substring (@w_cuenta, 2, 
                          datalength(@w_cuenta) - 1)

       select @w_pos = charindex('.',@w_cuenta)
   end

   -- AISLAR SIGUIENTE PARAMETRO DEL RESTO DE LA CUENTA 
   if @w_pos > 0 
   begin
       select @w_trama = substring (@w_cuenta, 1, @w_pos - 1)

       select @w_cuenta = substring (@w_cuenta, @w_pos + 1, 
                          datalength(@w_cuenta) - @w_pos)

       select @w_pos = charindex('.', @w_cuenta)
   end 
   else 
   begin
       select @w_trama = @w_cuenta
       select @w_cuenta = ''
   end

   -- CONDICION DE SALIDA DEL LAZO 
   if @w_trama = ''
     break

   -- DECODIFICAR PARAMETRO 
   select @w_ascii = ascii(substring(@w_trama, 1, 1))

   if @w_ascii >= 48 and @w_ascii <= 57 -- NUMERICO, PARTE FIJA
      select @o_cuenta_final = @o_cuenta_final + @w_trama 
   else 
   begin --0
      select @w_variable = null

      select  @w_variable =  case  
        when  @w_trama =   'GMON'  then   convert(varchar, @i_moneda) 
        when  @w_trama =   'GTIP'  then    @i_tipo_custodia
        when  @w_trama =   'GTIG'  then    @i_tipo_custodia
        when  @w_trama =   'GTCA'  then    @i_tipo_cca
        end


      if @w_variable is not null begin  
        
          select @w_resultado = re_substring
          from cob_conta..cb_relparam
          where re_empresa = convert(tinyint, @i_filial) 
          and   re_parametro  = @w_trama
          and   re_clave      = @w_variable
          if @@rowcount = 0 
            select @o_error = 'PARAMETRO1: ' + @w_trama + ' y/o CLAVE: ' +
                              @w_variable + ' NO EXISTEN'
      end 
      select @o_cuenta_final = @o_cuenta_final + @w_resultado

   end --0
 end -- FIN LAZO DE RESOLUCION

 select @o_cuenta_final = rtrim(ltrim(@o_cuenta_final))

-- SI NO EXISTE EL PARAMETRO PARA LA CUENTA
if @o_error != ''
  return 1
else
  return 0
go
--EXEC sp_procxmode 'dbo.sp_resuelve_cuenta', 'unchained'
go
IF OBJECT_ID('dbo.sp_resuelve_cuenta') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_resuelve_cuenta >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_resuelve_cuenta >>>'
go