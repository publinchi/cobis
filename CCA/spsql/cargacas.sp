/************************************************************************/
/*   Archivo            :  cargacas.sp                                  */
/*   Stored procedure   :  sp_cargar_castigos_masivos                   */
/*   Base de datos      :  cob_cartera                                  */
/*   Producto           :  Cartera                                      */
/*   Disenado por       :  Elcira Pelaez Burbano                        */
/*   Fecha de escritura :  Dic-09-2004                                  */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Cargar Informacion de castigos masivos para ser procesada por batc */
/************************************************************************/  

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_cargar_castigos_masivos')
   drop proc sp_cargar_castigos_masivos
go

create proc sp_cargar_castigos_masivos (
   @s_ssn               int         = null,
   @s_sesn              int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_srv               varchar(30) = null,
   @s_lsrv              varchar(30) = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,     
   @t_rty               char(1)     = null,
   @i_banco             cuenta      = null,
   @i_acta              varchar(14) = null,
   @i_fecha_cas        datetime    = null,
   @i_causal            char(2)     = null,
   @i_operacion         char(1)     = null,
   @i_estado            char(1)     = null
  
)
as
declare 
   @w_sp_name           varchar(32),
   @w_return            int,
   @w_error             int,
   @w_estado_ing        char(1),
   @w_estado            tinyint,
   @w_cliente           int,
   @w_situacion         catalogo,
   @w_fecha_cartera     datetime,
   @w_msg               varchar(100)

---  Captura nombre de Stored Procedure  
select @w_sp_name = 'sp_cargar_castigos_masivos'

select @w_fecha_cartera = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


/* INSERTAR ORDENES DE CASTIGO */
if @i_operacion = 'I' begin

   if @i_banco is null begin
      select @w_error = 710001, @w_msg = 'EL PARAMETRO DE ENTRADA @I_BANCO ES OBLIGATORIO'
      goto ERROR  --error del sistema
   end

   select 
   @w_estado  = op_estado,
   @w_cliente = op_cliente
   from ca_operacion
   where op_banco = @i_banco
   
   if @@rowcount= 0 begin
      select @w_error = 710001, @w_msg = 'NO EXISTE OPERACION'
      goto ERROR_I  -- mensaje al usuario
   end
   
   /* CONDICIONES DE SALIDA */
   if @w_estado = 4 begin
      select @w_error = 710003, @w_msg = 'OPERACION YA CASTIGADO'
      goto ERROR_I  -- mensaje al usuario
   end

   /* NO CASTIGAR OPERACIONES EN ESTADO QUE NO PROCESA */
   if exists(select 1 from ca_estado
   where es_codigo = @w_estado
   and   es_procesa = 'N')
   begin
      select @w_error = 710001, @w_msg = 'ESTADO OPERACION NO ADMITE CASTIGOS '
      goto ERROR_I  -- mensaje al usuario
   end
   
   insert into ca_castigo_masivo(           
   cm_banco,                cm_fecha_castigo,            cm_usuario,
   cm_fecha_ingreso,        cm_terminal,                 cm_estado,     
   cm_acta,                 cm_fecha_acta,               cm_causal)
   values(
   @i_banco,                @w_fecha_cartera,            @s_user,
   @s_date,                 @s_term,                     'I',
   @i_acta,                 @i_fecha_cas,               @i_causal )
   
   if @@error <> 0 begin
      select @w_error = 710001, @w_msg = 'ERROR AL INGRESAR ORDEN DE CASTIGO'
      goto ERROR  -- error de sistema
   end 
   
   /* SI TODO ESTA BIEN SE RETORNA OK AL FRONT END */
   select @w_msg = 'OK'
   
   ERROR_I:
   select @w_msg
   
   if @w_msg <> 'OK'
   begin

     update ca_castigo_masivo set
     cm_estado = 'X'
     where cm_banco = @i_banco

     if @@error <> 0 begin
        select @w_error = 710001, @w_msg = 'ERROR AL ACTUALIZAR ESTADO DE LA ORDEN DE CASTIGO'
        goto ERROR  -- error de sistema
     end 
   end

   return 0
   
end 


/* VALIDACION DE QUE TODAS LAS OPERACIONES DEL CLIENTE SE CASTIGUEN */
if @i_operacion = 'V' begin

   select distinct cliente = op_cliente
   into #clientes
   from ca_operacion, ca_castigo_masivo
   where op_banco  = cm_banco
   and   cm_estado = 'I'
   
   select banco = op_banco, cliente = op_cliente
   into #operaciones
   from ca_operacion, #clientes, ca_estado
   where op_cliente = cliente
   and   op_estado  = es_codigo
   and   es_procesa = 'S'
   and   op_estado <> 4
   
   delete #operaciones
   from ca_castigo_masivo
   where cm_banco  = banco
   and   cm_estado = 'I'
   
   /* RETORNAR AL FRONT END LA LISTA DE OPERACIONES CUYOS DEUDORES TIENEN MAS PRESTAMOS 
   A LOS INCLUIDOS EN LA TABLE DE CASTIGOS MASIVOS */
   select cm_banco, 'NO SE CASTIGAN TODAS LAS OPERACIONES DE ESTE DEUDOR'
   from ca_castigo_masivo, ca_operacion
   where cm_banco  = op_banco
   and   cm_estado = 'I'
   and   op_cliente in (select cliente from #operaciones)
   
   return 0

end


if @i_operacion = 'Q'
begin
    if @i_estado = 'I'
    begin
        select 'Fecha Castigo' = convert(char(12),cm_fecha_castigo,101),
               'Usuario'       = cm_usuario,
               'Estado'        = cm_estado,
               'Cantidad'      = count(1),
               'Causal'        = 'Obligaciones para Castigar'
        from ca_castigo_masivo
        where cm_usuario   = @s_user
        and   cm_terminal  = @s_term
        and   cm_estado    = 'I'
        group by cm_fecha_castigo,cm_usuario,cm_estado
        union
        select 'Fecha Castigo' = convert(char(12),cm_fecha_castigo,101),
               'Usuario'       = cm_usuario,
               'Estado'        = cm_estado,
               'Cantidad'      = count(1),
               'Causal'        = 'Cliente en estado Diferente A Castigo'
        from ca_castigo_masivo
        where cm_usuario    = @s_user
        and   cm_terminal   = @s_term
        and   cm_estado     = 'X'
        group by cm_fecha_castigo,cm_usuario,cm_estado
    end

    if @i_estado = 'P'
    begin
        select 'Fecha Castigo' = convert(char(12),cm_fecha_castigo,101),
               'Usuario'       = cm_usuario,
               'Estado'        = cm_estado,
               'Cantidad'      = count(1),
               'Obligaciones Castigadas'
        from ca_castigo_masivo
        where cm_usuario   = @s_user
        and   cm_terminal  = @s_term
        and   cm_estado    = 'P'
        group by cm_fecha_castigo,cm_usuario,cm_estado
    end
end

if @i_operacion = 'D'
begin
    delete ca_castigo_masivo
    where cm_estado in ('I','X')
    and   convert(varchar(10), cm_fecha_ingreso, 101) = convert(varchar(10), @s_date, 101)

    if @@error <> 0 
    begin
        select @w_error = 710550
        goto ERROR
    end 
end


return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error

go
