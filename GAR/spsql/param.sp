USE cob_custodia
GO

if exists (select 1 from sysobjects where name = 'sp_parametro')
    drop proc sp_parametro
go

create proc sp_parametro  (
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
   @i_modo               smallint = null,
   @i_producto           catalogo = null,
   @i_nemonico           catalogo = null,
   @i_tipo               char(1) = null 
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_float              float,
   @w_tinyint            tinyint,
   @w_smallint           smallint,
   @w_int                int,
   @w_money              money,
   @w_rowcount           int

select @w_today = convert(varchar(10),@s_date,101)
select @w_sp_name = 'sp_parametro'
/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19233 and @i_operacion = 'V')    
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    --return 1 
    RETURN 1901006
end

if @i_operacion = 'V'
begin
      select @w_tinyint  = pa_tinyint,
             @w_smallint = pa_smallint,
             @w_int      = pa_int,
             @w_float    = pa_float,
             @w_money    = pa_money
      from cobis..cl_parametro 
      where pa_producto = @i_producto
      and pa_nemonico = @i_nemonico
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

         if @w_rowcount = 0
         begin
            select @w_error = 1901005
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            --return 1 
            RETURN @w_error
         end

         if @i_tipo = 'F'
            select @w_float
         if @i_tipo = 'I'
            select @w_int
         if @i_tipo = 'S'
            select @w_smallint
         if @i_tipo = 'T'
            select @w_tinyint
         if @i_tipo = 'M'
            select @w_money
end

GO

