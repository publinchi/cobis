/************************************************************************/
/*	Archivo:		val_refe.sp				*/
/*	Stored procedure:	sp_valor_referencial			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Fabian Espinosa				*/
/*	Fecha de escritura:	05/31/1995				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este stored procedure maneja las tasas.				*/
/*	I: Insercion de tasas						*/
/*	S: Busqueda de tasas						*/
/*	H: Help de tasas						*/
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	05/31/1995	Fabian Espinosa	Emision inicial			*/
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_valor_referencial')
	drop proc sp_valor_referencial
go
---INC. 112524 ABR.22.2013
create proc sp_valor_referencial (
@s_date         datetime    = null,
@s_ofi          smallint    = null,
@s_term         varchar(30) = null,
@s_user         login       = null,
@i_operacion	char (1),
@i_tipo		    varchar(10)    = null,
@i_tipoh	    char(1)     = null,
@i_fecha_vig	datetime    = null,
@i_valor	    float       = null,
@i_tasa_valor   varchar(10)    = null,
@i_periodicidad char(1)	    = null,
@i_modalidad	char(1)	    = null,
@i_secuencial   int         = 0,
@i_formato_fecha int        = 101
)
as
declare 
@w_sp_name	varchar(64),
@w_error	int,
@w_fecha        datetime,
@w_return       int,
@w_clave1       varchar(255),
@w_clave2       varchar(255),
@w_clave3       varchar(255),
@w_clave4       varchar(255),
@w_clave5       varchar(255),
@w_tipo		    varchar(10),
@w_fecha_vig	datetime,
@w_vr_secuencial   int,
@w_secuencial      int,
@w_producto        tinyint


/*  Inicializar variables */
select @w_sp_name = 'sp_valor_referencial'


  select @w_producto = pd_producto
    from cobis..cl_producto
   where pd_abreviatura = 'CCA'
   set transaction isolation level read uncommitted

  select @w_fecha = fc_fecha_cierre
    from cobis..ba_fecha_cierre
   where fc_producto = @w_producto



/* ** Insert ** */
if @i_operacion = 'I' 
begin
   create table #valores_referenciales (
	tipo           varchar(10),
	fecha          datetime,
	secuencial     int,
	)

   begin tran

   select @w_secuencial = 0

   select @w_secuencial = max(vr_secuencial)
   from ca_valor_referencial 
   where vr_tipo      = @i_tipo
   and   vr_fecha_vig = @i_fecha_vig

   if @w_secuencial > 0

      update ca_valor_referencial 
      set vr_valor = @i_valor
      where vr_fecha_vig = @i_fecha_vig
      and   vr_tipo      = @i_tipo
      and   vr_secuencial = @w_secuencial 

   else begin

      exec @w_secuencial = sp_gen_sec
           @i_operacion  = -1

      insert into ca_valor_referencial 
      (vr_tipo, vr_valor , vr_fecha_vig,
       vr_secuencial)
      values
      (@i_tipo, @i_valor, @i_fecha_vig,
       @w_secuencial)

      if @@error <> 0 begin
         select @w_error = 703100
         goto ERROR
      end
   end

   select @w_clave1 = convert(varchar(255),@i_tipo)
   select @w_clave2 = convert(varchar(255),@i_fecha_vig)
   select @w_clave3 = convert(varchar(255),@w_secuencial)

   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_valor_referencial',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2,
   @i_clave3  = @w_clave3

   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR
   end

   
   insert into #valores_referenciales
   select vr_tipo, vr_fecha_vig, vr_secuencial
   from ca_valor_referencial
   where vr_fecha_vig > @i_fecha_vig
   and   vr_tipo = @i_tipo
   
   declare cur_valor_referencial cursor for
   select tipo, fecha, secuencial 
   from #valores_referenciales
   order by fecha, secuencial
   for read only

   open cur_valor_referencial

   fetch cur_valor_referencial into
   @w_tipo,
   @w_fecha_vig,
   @w_vr_secuencial

   while @@fetch_status = 0 begin

      if @@fetch_status = -1 begin    /* error en la base */
          select @w_error = 70899
          goto  ERROR
      end

      exec @w_secuencial = sp_gen_sec
           @i_operacion  = -1

      update ca_valor_referencial
      set    vr_secuencial = @w_secuencial
      where  vr_tipo = @w_tipo
      and    vr_fecha_vig = @w_fecha_vig
      and    vr_secuencial = @w_vr_secuencial
   
      if @@error <> 0 begin
         select @w_error = 710002
         goto ERROR
      end

      fetch cur_valor_referencial into
      @w_tipo,
      @w_fecha_vig,
      @w_vr_secuencial

   end

   close cur_valor_referencial
   deallocate cur_valor_referencial

   commit tran
end




/* ** Select ** */
if @i_operacion = 'S' 
begin
   select @i_fecha_vig = isnull(@i_fecha_vig, ' ')

   create table #registros_ref (
   re_secuencial     numeric (5,0) identity,
   re_tipo           varchar(10),
   re_descripcion    varchar(64),
   re_tipo_tasa      char(1),
   re_modalidad      char(1),
   re_periodicidad   varchar(64),
   re_fecha_vig      datetime,
   re_valor          float)

   insert into #registros_ref
   select distinct
   re_tipo         = vr_tipo,  
   re_descripcion  = tv_descripcion,
   re_tipo_tasa    = tv_tipo_tasa,
   re_modalidad    = tv_modalidad,
   re_periodicidad = td_descripcion,
   re_fecha_vig    = vr_fecha_vig,
   re_valor        = vr_valor
   from	  ca_valor_referencial, ca_tasa_valor, ca_tdividendo
   where  vr_fecha_vig   >= @i_fecha_vig 
   and    tv_nombre_tasa  = vr_tipo
   and    tv_estado       = 'V'
   and    tv_periodicidad = td_tdividendo
   and    (vr_tipo  = @i_tasa_valor or @i_tasa_valor is null)
   order by vr_fecha_vig

   set rowcount 20

   select
   'Tipo Valor'     = re_tipo,
   'Descripcion'    = re_descripcion,
   'Tipo Tasa'      = re_tipo_tasa,
   'Modalidad'      = re_modalidad,
   'Periodicidad'   = substring(re_periodicidad,1,15),
   'Fecha Vigencia' = convert(varchar(10),re_fecha_vig,@i_formato_fecha),
   'Valor'          = re_valor,
   'Secuencial'     = convert(int, re_secuencial)
   from	 #registros_ref
   where re_secuencial > @i_secuencial

   set rowcount 0
end



/* ** Help ** */
if @i_operacion = 'H' begin

   if @i_tipoh = 'A' begin

      select @i_tipo= isnull(@i_tipo, ' ')

      --set rowcount 20
      select
      'Tipo Valor'     = vr_tipo,
      'Descripcion'    = tv_descripcion,
      'Tipo Tasa'      = tv_tipo_tasa,
      'Valor'          = vr_valor,
      'Sec.'           = vr_secuencial,
      'Modalidad'      = tv_modalidad,
      'Periodicidad'   = substring(td_descripcion,1,15)
      from ca_valor_referencial z,ca_tasa_valor,ca_tdividendo
      where vr_tipo > @i_tipo
      and tv_nombre_tasa = vr_tipo
      and tv_estado      = 'V'
      and tv_periodicidad= td_tdividendo
      and vr_secuencial = (select max(vr_secuencial)
                           from ca_valor_referencial
	                   where vr_tipo = z.vr_tipo
	                   and   vr_fecha_vig <= @w_fecha)
      order by vr_tipo
      set rowcount 0           
                
   end

   if @i_tipoh = 'V' begin
      select
      'Tipo Valor'     = vr_tipo,
      'Descripcion'    = tv_descripcion,
      'Tipo Tasa'      = tv_tipo_tasa,
      'Valor'          = vr_valor
      from ca_valor_referencial z,ca_tasa_valor
      where vr_tipo     = @i_tipo
      and tv_nombre_tasa = vr_tipo
      and tv_estado      = 'V'
      and vr_secuencial = (select max(vr_secuencial)
                           from ca_valor_referencial
                           where vr_tipo = z.vr_tipo
                           and   vr_fecha_vig <= @w_fecha)

      if @@rowcount <> 1 begin
         select @w_error = 701085
         goto ERROR
      end
   end
end


return 0

ERROR:
exec cobis..sp_cerror
@t_debug= 'N',
@t_file = null,
@t_from = @w_sp_name,
@i_num  = @w_error 

return @w_error

go