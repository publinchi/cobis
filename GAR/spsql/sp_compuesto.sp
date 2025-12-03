/************************************************************************/
/* Archivo:                   sp_compuesto.sp                               */
/* Stored procedure:          sp_compuesto                              */
/* Base de datos:             cob_custodia                              */
/* Producto:                  Garantias                                 */
/* Disenado por:              Rodrigo Garces                            */
/*                            Luis Alfredo Castellanos                  */
/* Fecha de escritura:        Junio-1995                                */
/************************************************************************/
/*                            IMPORTANTE                                */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* "Cobiscorp"                                                          */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteración o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de Cobiscorp o su representante.               */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Este programa procesa las transacciones de:                          */
/* Descifra el código compuesto de la garantía                          */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA        AUTOR     RAZON                                         */
/* Jun/1995               Emisión Inicial                               */
/* 15/Sep/1997  FPatino   FPL1 Seleccionar el tipo y el consecutivo de  */
/*                        la garantía, nueva tran 'S'                   */
/* 05/Mar/1998  NVelasco  NVR-BE Personalización Banco del Estado Cambio*/
/*                        en conformación del número Gtia Long.Oficina 4*/
/* 10/Abr/2015  AGuevara  Formato número de garantia FIE GAR-H001       */
/* 10/Abr/2015  AGuevara  Formato número de garantia FIE GAR-H001       */
/* 25-06-2021   PQU       ajustes por integracion de version base XSELL"*/
/************************************************************************/
USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_compuesto') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_compuesto
    IF OBJECT_ID('dbo.sp_compuesto') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_compuesto >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_compuesto >>>'
END
go

create proc sp_compuesto  (
        @s_ssn                int         = null,
        @s_date               datetime    = null,
        @s_user               login       = null,
        @s_term               descripcion = null,
        @s_corr               char(1)     = null,
        @s_ssn_corr           int         = null,
        @s_ofi                smallint    = null,
        @t_rty                char(1)     = null,
        @t_trn                smallint    = null,
        @t_debug              char(1)     = 'N',
        @t_file               varchar(14) = null,
        @t_from               varchar(30) = null,
        @i_operacion          char(1)     = null,
        @i_compuesto          varchar(64) = null,
   @o_tmitigador         varchar(20) = null out, --PQU
   @o_tipo_cus           varchar(64) = null out, --PQU
   @o_oficina            smallint    = null out, --PQU
   @o_secuencia          int         = null out, --PQU
   @o_filial             tinyint     = null out,
   @o_sucursal           smallint    = null out,
   @o_tipo               varchar(64) = null out,
   @o_custodia           int         = null out
)       
as      
        
declare    @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_parte              tinyint,
   @w_inicio             tinyint,
   @w_contador           tinyint,
   @w_longitud           tinyint,
   @w_caracter           char(1),
   @w_compuesto          varchar(64)


select @w_today = getdate()
select @w_sp_name = 'sp_compuesto'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19245 and @i_operacion = 'Q') 
     
begin
/* tipo de transaccion no corresponde */
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901006
   return 1 
end

if @i_operacion = 'Q' 
begin
      select @o_filial   = 1,
      @o_sucursal = convert(int,(substring(@i_compuesto,1,4))),
      @o_custodia = convert(int,(substring(@i_compuesto,datalength(@i_compuesto)-10+1,10))),
      @o_tipo     = substring(@i_compuesto,5,datalength(@i_compuesto)-14)
      return 0
end

if @i_operacion = 'S' --PQU integraciÃ³n se aÃ±ade
   begin
   select @o_tmitigador = '',
          @o_tipo_cus   = substring(@i_compuesto,5,datalength(@i_compuesto)-14),
          @o_oficina    = convert(int,(substring(@i_compuesto,1,4))),
          @o_secuencia  = convert(int,(substring(@i_compuesto,datalength(@i_compuesto)-10+1,10)))

   select @o_tmitigador,
          @o_tipo_cus,
          @o_oficina,
          @o_secuencia 
   
   return 0
end

                                                                                                                                                                            

GO

