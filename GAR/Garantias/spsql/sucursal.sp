/****************************************************************/
/* ARCHIVO:              sucursal.sp                            */
/* Stored procedure:	 sp_sucursal	          	            */
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

IF OBJECT_ID('dbo.sp_sucursal') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_sucursal
    IF OBJECT_ID('dbo.sp_sucursal') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_sucursal >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_sucursal >>>'
END
go
create proc dbo.sp_sucursal(
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_filial             tinyint = null,
   @i_oficina            smallint = null,
   @i_cond1              varchar(10)  = null,
   @i_sucursal           smallint = null,
   @i_param1             varchar(10) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_error              int,         
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_oficina            smallint,
   @w_sucursal           smallint, 
   @w_subtipo            char(1),
   @w_nombre             varchar(25)

select @w_today = getdate()
select @w_sp_name = 'sp_sucursal'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19130 and @i_operacion = 'Q') or
   (@t_trn <> 19131 and @i_operacion = 'F') or
   (@t_trn <> 19132 and @i_operacion = 'O') 

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
      /* Chequeo de Existencias */
      /**************************/
    /*select
         @w_oficina  = of_oficina,
         @w_sucursal = a_sucursal,
         @w_filial   = of_filial,
         @w_subtipo  = of_subtipo,
         @w_nombre   = of_nombre

    from cobis..cl_oficina 
    where 
         of_filial = @i_filial
         and of_oficina = @i_oficina*/

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0

    if @w_existe = 1
    begin
      if @w_subtipo = 'S'
         select @w_oficina
      else
         select @w_sucursal 
    end
      select @w_nombre
end 


if @i_operacion = 'O'    
begin
   set rowcount 20
   /*if @i_sucursal is null
      select @i_sucursal = convert(smallint,@i_param1)
   select "CODIGO" = of_oficina, "SUCURSAL"= of_nombre
     from cobis..cl_oficina
   where of_filial  = convert(tinyint,@i_cond1)
     and of_subtipo = 'S'       
     and (of_oficina > @i_oficina or  @i_oficina is null) 
   order by of_filial,of_oficina*/
   if @@rowcount = 0
      if @i_oficina is null /* Modo 0 */
      begin
         select @w_error  = 1901003
         goto ERROR
      end
      else
      begin
         select @w_error  = 1901004
         goto ERROR
      end
end

/*if @i_operacion = 'F'    
begin
   select of_nombre
     from cobis..cl_oficina
    where of_oficina = @i_oficina
      and of_filial  = @i_filial
      and of_subtipo = 'S'
      --and a_sucursal is null
  if @@rowcount = 0
  begin
     select @w_error = 1901005
     goto ERROR
  end
end
return 0*/
ERROR:  
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return 1
go
--EXEC sp_procxmode 'dbo.sp_sucursal', 'unchained'
go
IF OBJECT_ID('dbo.sp_sucursal') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_sucursal >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_sucursal >>>'
go