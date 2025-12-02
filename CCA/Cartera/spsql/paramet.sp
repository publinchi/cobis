/************************************************************************/
/*	Archivo:		paramet.sp				*/
/*	Stored procedure:	sp_parametro   				*/
/*	Base de datos: 	        cobis					*/
/*	Producto:               Clientes				*/
/*	Disenado por:           Mauricio Bayas/Sandra Ortiz		*/
/*	Fecha de escritura:     19/Ene/1994				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su  uso no autorizado  queda expresamente  prohibido asi como	*/
/*	cualquier   alteracion  o  agregado  hecho por  alguno de sus	*/
/*	usuarios   sin el debido  consentimiento  por  escrito  de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa maneja los parametros generales CCA	 	*/
/*      I: Insercion de parametros generales CCA                        */
/*      U: Actualizacion de parametros generales CCA                    */
/*	S: Consulta de parametros generales CCA				*/
/*	Q: Query de parametros generales CCA				*/
/************************************************************************/
/*                           MODIFICACIONES                             */
/*	FECHA		AUTOR		RAZON				*/
/*	19/ENE/1994     R. Minga V.    	Emision Inicial			*/
/*	22/Abr/94	F.Espinosa	Parametros tipo "S"		*/
/*					Transacciones de Servicio	*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_parametro')
   drop proc sp_parametro
go

create proc sp_parametro (
@i_operacion		char(2),
@i_modo			tinyint     = null,
@i_parametro   	 	descripcion = null,
@i_nemonico    	  	char(6)     = null,
@i_tipo        		char(1)     = null,
@i_char         	varchar(30) = null,
@i_tinyint      	tinyint     = null,
@i_smallint  		smallint    = null,
@i_int         	 	int         = null,
@i_money       		money       = null,
@i_datetime      	datetime    = null,
@i_float         	float       = null,
@i_producto		char(3)     = null
)
as
declare 
@w_sp_name	varchar(32),
@w_error	int

/** INICIALIZAR VARIABLES **/
select @w_sp_name = 'sp_parametro'

/* ** Insert ** */
if @i_operacion = 'I' begin
   /* VERIFICAR QUE PARAMETRO NO EXISTA */
   if exists ( select 1 	
   from cobis..cl_parametro	
   where pa_nemonico = @i_nemonico and pa_producto = @i_producto) begin
      select @w_error = 151046
      goto ERROR
   end

   begin tran
   /* Insertar los datos de entrada */
   insert into cobis..cl_parametro 
   (pa_parametro, pa_nemonico, pa_tipo,
   pa_char,       pa_tinyint,  pa_smallint,
   pa_int,        pa_money,    pa_datetime, 
   pa_float,      pa_producto)
   values 
   (@i_parametro, @i_nemonico, @i_tipo,
   @i_char,       @i_tinyint,  @i_smallint,
   @i_int,        @i_money,    @i_datetime, 
   @i_float,      @i_producto)

   if @@error != 0 begin
      select @w_error = 103054
      goto ERROR
   end
   commit tran
end

/* ** Update ** */
if @i_operacion = 'U' begin
   begin tran
   update cobis..cl_parametro 
   set pa_parametro = @i_parametro,
   pa_tipo          = @i_tipo,
   pa_char          = @i_char,
   pa_tinyint       = @i_tinyint,
   pa_smallint      = @i_smallint, 
   pa_int           = @i_int, 
   pa_money         = @i_money, 
   pa_datetime      = @i_datetime, 
   pa_float         = @i_float
   where pa_nemonico = @i_nemonico
   and   pa_producto = @i_producto
   if @@error != 0 begin
      select @w_error = 155024
      goto ERROR
   end 
   commit tran
end

/* ** Search** */
if @i_operacion = 'S' begin
   if @i_nemonico is null
      select @i_nemonico = ' '
 
   set rowcount 20
   if @i_modo = 0
      select 
      'Nemonico'        = pa_nemonico ,
      'Producto'        = pa_producto,
      'Parametro'       = convert(char(64),pa_parametro),
      'Valor'           = pa_char,
      'Valor1'          = pa_tinyint,
      'Valor2'          = pa_smallint,
      'Valor3'          = pa_int,
      'Valor4'          = pa_money, 
      'Valor5'          = pa_float,
      'Valor6'          = convert(char(10),pa_datetime,103)
      from  cobis..cl_parametro
      where pa_producto = 'CCA' 
      and   pa_nemonico > @i_nemonico
      order by pa_nemonico
      set transaction isolation level read uncommitted

   if @i_modo = 1
      select 'Nemonico' = pa_nemonico ,
      'Producto'        = pa_producto,
      'Parametro'       = convert(char(64),pa_parametro),
      'Valor1'          = pa_char,
      'Valor2'          = pa_tinyint,
      'Valor3'          = pa_smallint,
      'Valor4'          = pa_int,
      'Valor5'          = pa_money, 
      'Valor6'          = pa_float,
      'Valor7'          = convert(char(10),pa_datetime,103)
      from  cobis..cl_parametro
      where pa_nemonico > @i_nemonico
      and   pa_producto = 'CCA' 
      order by pa_nemonico
      set transaction isolation level read uncommitted

   set rowcount 0
end

if @i_operacion = 'SC' begin
   set rowcount 20
   if @i_modo = 0
      select 'Nemonico' = pa_nemonico ,
      'Producto'        = pa_producto,
      'Parametro'       = convert(char(30),pa_parametro),
      'Valor1'          = pa_char,
      'Valor2'          = pa_tinyint,
      'Valor3'          = pa_smallint,
      'Valor4'          = pa_int,
      'Valor5'          = pa_money, 
      'Valor6'          = pa_float,
      'Valor7'          = convert(char(10),pa_datetime,103)
      from  cobis..cl_parametro 
      where pa_producto = @i_producto  
      order by pa_nemonico
      set transaction isolation level read uncommitted

   if @i_modo = 1
      select 'Nemonico' = pa_nemonico ,
      'Producto'        = pa_producto,
      'Parametro'       = convert(char(30),pa_parametro),
      'Valor1'          = pa_char,
      'Valor2'          = pa_tinyint,
      'Valor3'          = pa_smallint,
      'Valor4'          = pa_int,
      'Valor5'          = pa_money, 
      'Valor6'          = pa_float,
      'Valor7'          = convert(char(10),pa_datetime,103)
      from  cobis..cl_parametro
      where pa_producto = @i_producto
      and   pa_nemonico > @i_nemonico 
      order by pa_nemonico
      set transaction isolation level read uncommitted

   set rowcount 0
end

/* ** Query de parametro dado el registro ** */
if @i_operacion = 'Q' begin
   select 'Nemonico' = pa_nemonico ,
   'Parametro'       = convert(varchar(64),pa_parametro),
   'Tipo'            = pa_tipo,
   'Valor1'          = pa_char,
   'Valor2'          = pa_tinyint,
   'Valor3'          = pa_smallint,
   'Valor4'          = pa_int,
   'Valor5'          = pa_money, 
   'Valor6'          = pa_float,
   'Valor7'          = convert(char(10),pa_datetime,101),
   'Cod.Prod.'       = pd_producto,
   'Des.Prod.'       = pd_descripcion,
   'Producto'        = pa_producto
   from  cobis..cl_parametro, cobis..cl_producto
   where pa_nemonico = @i_nemonico 
   and   pa_producto = pd_abreviatura
   and   pa_producto = 'CCA'
   set transaction isolation level read uncommitted
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug    = 'N',	
@t_file     = null,
@t_from     = @w_sp_name,	 
@i_num      = @w_error

return @w_error

go
