/************************************************************************/
/*      Archivo:                est_manu.sp                             */
/*      Stored procedure:       sp_estados_man                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces                                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				PROPOSITO				*/
/*	Manejo de los estados manuales de una operacion			*/
/*	I: Creacion de cambio de estado					*/
/*	U: Actualizacion de cambio de estado				*/
/*	D: Eliminacion de cambio de estado				*/
/*	S: Busqueda de cambio de estado					*/
/*	A: Ayuda de cambio de estado					*/
/*	V: Descripcion de cambio de estado				*/
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_estados_man')
    drop proc sp_estados_man
go

create proc sp_estados_man (
   @s_user               login       = null,
   @s_date               datetime    = null,
   @s_ofi                smallint    = null,
   @s_term               varchar(30) = null,
   @i_toperacion         catalogo    = '',
   @i_operacion          char(1)     = null,
   @i_estado_ini         varchar(30) = '', 
   @i_estado_fin         varchar(30) = '', 
   @i_tipo               char(1)     = '',
   @i_dias_cont	         int         = -99999,
   @i_dias_fin	         int         =  99999,
   @i_perfil             cuenta      = null
)
as

declare
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_estado_ini         tinyint,
   @w_estado_fin         tinyint,
   @w_tipo               char(1),
   @w_error              int,
   @w_clave1             varchar(255),
   @w_clave2             varchar(255),
   @w_clave3             varchar(255),
   @w_clave4             varchar(255)

select @w_sp_name = 'sp_estados_man'


if @i_operacion = 'S'
begin
	if isnull(@i_tipo, '') = '' select @i_tipo = 'M'
end


if @i_tipo <> 'M' and @i_tipo <> 'D'
   select @i_estado_fin = @i_estado_ini


if @i_tipo =  'D' 
   select @i_estado_fin = @i_estado_fin



select @w_estado_ini = es_codigo
from   ca_estado
where  es_descripcion =rtrim(@i_estado_ini)

select @w_estado_fin = es_codigo
from   ca_estado
where  es_descripcion =rtrim(@i_estado_fin)

select @w_tipo  = em_tipo_cambio
from cob_cartera..ca_estados_man
where em_toperacion     = @i_toperacion 
and   em_tipo_cambio    = @i_tipo 
and   em_estado_ini     = @w_estado_ini
and   em_estado_fin     = @w_estado_fin

if @@rowcount > 0 select @w_existe = 1
else select @w_existe = 0

/* Insercion del registro */

if @i_operacion = 'I' begin

   if @w_existe = 1 begin
      select @w_error = 701155
      goto ERROR 
   end

   if @w_estado_ini = @w_estado_fin and @i_tipo ='M' begin
     select @w_error = 710014
     goto ERROR 
   end

   if @i_tipo <> 'M' and @i_tipo <> 'D' and exists(select 1 from ca_estados_man
                                where  em_toperacion  = @i_toperacion
                                and    em_estado_ini  = @w_estado_ini
                                and    em_tipo_cambio = @i_tipo
                                and    em_tipo_cambio <> 'M')  begin
      select @w_error = 710015
      goto ERROR 
   end

   if @i_tipo <> 'M' and  @i_tipo <> 'D' and exists (
                      select 1 from ca_estados_man
                      where em_toperacion = @i_toperacion
                      and em_tipo_cambio  = @i_tipo
                      and ( @i_dias_cont between em_dias_cont and em_dias_fin
                      or @i_dias_fin  between em_dias_cont and em_dias_fin )) begin
      select @w_error = 710080
      goto ERROR 
   end
   
  
   begin tran

   insert into ca_estados_man (
   em_toperacion, em_tipo_cambio, em_estado_ini,
   em_estado_fin, em_dias_cont,   em_dias_fin)
   values ( 
   @i_toperacion, @i_tipo,        @w_estado_ini,
   @w_estado_fin, @i_dias_cont,   @i_dias_fin)

   if @@error <> 0 begin
      select @w_error = 703106
      goto ERROR 
   end

   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_tipo)
   select @w_clave3 = convert(varchar(255),@w_estado_ini)
   select @w_clave4 = convert(varchar(255),@w_estado_fin)

   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_estados_man',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2,
   @i_clave3  = @w_clave3,
   @i_clave4  = @w_clave4
   
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR
   end

   commit tran

end

/* Actualizacion del registro */

if @i_operacion = 'U' begin

   if @w_existe = 0 begin
      select @w_error = 701156
      goto ERROR 
   end

   if @i_tipo <> 'M' and @i_tipo <> 'D' and exists (
                     select 1 from ca_estados_man
                     where em_toperacion = @i_toperacion
                     and em_tipo_cambio  = @i_tipo
                     and em_estado_ini  <> @w_estado_ini 
                     and em_estado_fin  <> @w_estado_fin
                     and (@i_dias_cont between em_dias_cont and em_dias_fin
                     or @i_dias_fin  between em_dias_cont and em_dias_fin ))
   begin
      select @w_error = 710080
      goto ERROR 
   end

   begin tran

   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_tipo)
   select @w_clave3 = convert(varchar(255),@w_estado_ini)
   select @w_clave4 = convert(varchar(255),@w_estado_fin)

   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_estados_man',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2,
   @i_clave3  = @w_clave3,
   @i_clave4  = @w_clave4

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end     


   update cob_cartera..ca_estados_man set 
   em_dias_cont = @i_dias_cont,
   em_dias_fin  = @i_dias_fin
   where em_toperacion  = @i_toperacion 
   and   em_tipo_cambio = @i_tipo  
   and   em_estado_ini  = @w_estado_ini 
   and   em_estado_fin  = @w_estado_fin

   if @@error <> 0 begin
      select @w_error = 705066
      goto ERROR 
   end

   commit tran
end


/* Eliminacion de registros */

if @i_operacion = 'D' begin

   if @w_existe = 0 begin
     select @w_error = 701157
     goto ERROR 
   end
   
   begin tran

   select @w_clave1 = convert(varchar(255),@i_toperacion)
   select @w_clave2 = convert(varchar(255),@i_tipo)
   select @w_clave3 = convert(varchar(255),@w_estado_ini)
   select @w_clave4 = convert(varchar(255),@w_estado_fin)

   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_estados_man',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2,
   @i_clave3  = @w_clave3,
   @i_clave4  = @w_clave4

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end        

   delete cob_cartera..ca_estados_man
   where em_toperacion  = @i_toperacion 
   and   em_tipo_cambio = @i_tipo
   and   em_estado_ini  = @w_estado_ini
   and   em_estado_fin  = @w_estado_fin

   if @@error <> 0 begin
      select @w_error = 707069
      goto ERROR 
   end    

   commit tran

end

/*BUSQUEDA DE REGISTROS*/
if @i_operacion = 'S' begin

   --if @i_tipo = '' and @i_toperacion <> '' begin
   if @i_toperacion <> '' begin
      /*CONSULTA DATOS SOLO DEL PARAMETRO INGRESADO*/   

      set rowcount 45

      select 
      'TIPO OP.'          = em_toperacion,
      'DESC. OP.'         = substring(D.valor,1,20), 
      'TIPO'              = em_tipo_cambio,
      'ESTADO ANT.'       = substring(A.es_descripcion,1,20),
      'ESTADO FINAL'      = substring(B.es_descripcion,1,20),
      'DIAS INICIO'       = em_dias_cont,
      'DIAS FIN'          = em_dias_fin
      from  ca_estados_man,ca_estado A,ca_estado B,
            cobis..cl_tabla C, cobis..cl_catalogo D 
      where em_tipo_cambio= @i_tipo
	  and   em_toperacion = @i_toperacion 
      and   em_estado_ini = A.es_codigo
      and   em_estado_fin = B.es_codigo
      and   C.tabla       = 'ca_toperacion'
      and   C.codigo      = D.tabla
      and   D.codigo      = em_toperacion
 
      order by em_toperacion, em_tipo_cambio, em_estado_ini, em_estado_fin

      select 45

   end
   else begin
  
      /*CONSULTA DE TODOS O SIGUIENTES DATOS*/   
      set rowcount 45

      select 
      'TIPO OP.'          = em_toperacion,
      'DESC. OP.'         = substring(D.valor,1,20), 
      'TIPO'              = em_tipo_cambio,
      'ESTADO ANT.'       = substring(A.es_descripcion,1,20),
      'ESTADO FINAL'      = substring(B.es_descripcion,1,20),
      'DIAS INICIO'       = em_dias_cont,
      'DIAS FIN'          = em_dias_fin
   
      from  ca_estados_man,ca_estado A,ca_estado B,
            cobis..cl_tabla C, cobis..cl_catalogo D 
      where em_tipo_cambio = @i_tipo and 
	        (em_toperacion > @i_toperacion or 
            (em_toperacion = @i_toperacion and em_tipo_cambio > @i_tipo) or
            (em_toperacion = @i_toperacion and em_tipo_cambio = @i_tipo and
             em_estado_ini > @w_estado_ini ) or
            (em_toperacion = @i_toperacion and em_tipo_cambio = @i_tipo and
             em_estado_ini = @w_estado_ini and em_estado_fin > @w_estado_fin))
      and   em_estado_ini = A.es_codigo
      and   em_estado_fin = B.es_codigo
      and   C.tabla       = 'ca_toperacion'
      and   C.codigo      = D.tabla
      and   D.codigo      = em_toperacion
 
      order by em_toperacion, em_tipo_cambio, em_estado_ini, em_estado_fin

      select 45

   end
end

if @i_operacion = 'V' begin
   select pe_descripcion
   from   cob_conta..cb_perfil
   where  pe_producto = 7 -- Cartera
   and    pe_perfil   = @i_perfil

   if @@rowcount = 0 begin
      select @w_error = 701158
      goto ERROR 
   end
end

if @i_operacion = 'A' begin
   set rowcount 20

   select
   'Perfil'      =pe_perfil,
   'Descripción' =pe_descripcion
   from cob_conta..cb_perfil
   where pe_producto = 7 -- Cartera
   and   pe_perfil  > @i_perfil
   order by pe_perfil

  set rowcount 0
end

return 0

ERROR:
   exec cobis..sp_cerror 
   @t_debug='N',@t_file=null,  
   @t_from=@w_sp_name,   @i_num = @w_error
   return @w_error
go
