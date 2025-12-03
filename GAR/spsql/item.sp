/*************************************************************************/
/*   Archivo:              item.sp                                       */
/*   Stored procedure:     sp_item                                       */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_item') IS NOT NULL
    DROP PROCEDURE dbo.sp_item
go
create proc dbo.sp_item (
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
   @i_tipo_custodia      descripcion  = null,
   @i_item               tinyint  = null,
   @i_nombre             descripcion  = null,
   @i_detalle            descripcion  = null,
   @i_tipo_dato          char(  1)  = null,
   @i_filial		 tinyint = null,
   @i_sucursal           smallint = null,
   @i_custodia           int = null,
   @i_mandatorio         char(1) = null,
   @i_factura            char(1) = null,
   @i_param1             descripcion = null,
   @i_param2             descripcion = null,
   @i_secuencial1	 tinyint = null,
   @i_secuencial2	 tinyint = null,
   @i_secuencial3	 tinyint = null,
   @i_secuencial4	 tinyint = null,
   @i_secuencial5	 tinyint = null,
   @i_secuencial6	 tinyint = null,
   @i_secuencial7	 tinyint = null,
   @i_secuencial8	 tinyint = null,
   @i_secuencial9	 tinyint = null,
   @i_secuencial10	 tinyint = null,
   @i_secuencial11	 tinyint = null,
   @i_secuencial12	 tinyint = null,
   @i_secuencial13	 tinyint = null,
   @i_secuencial14	 tinyint = null,
   @i_secuencial15	 tinyint = null,
   @i_secuencial16	 tinyint = null,
   @i_secuencial17	 tinyint = null,
   @i_secuencial18	 tinyint = null,
   @i_secuencial19	 tinyint = null,
   @i_secuencial20	 tinyint = null,
   @i_secuencial21	 tinyint = null,
   @i_secuencial22	 tinyint = null,
   @i_secuencial23	 tinyint = null,
   @i_secuencial24	 tinyint = null,
   @i_secuencial25	 tinyint = null,
   @i_secuencial26	 tinyint = null,
   @i_secuencial27	 tinyint = null,
   @i_secuencial28	 tinyint = null,
   @i_secuencial29	 tinyint = null,
   @i_secuencial30	 tinyint = null,
   @i_valor1		 descripcion = null,
   @i_valor2		 descripcion = null,
   @i_valor3		 descripcion = null,
   @i_valor4		 descripcion = null,
   @i_valor5		 descripcion = null,
   @i_valor6		 descripcion = null,
   @i_valor7		 descripcion = null,
   @i_valor8		 descripcion = null,
   @i_valor9		 descripcion = null,
   @i_valor10		 descripcion = null,
   @i_valor11		 descripcion = null,
   @i_valor12		 descripcion = null,
   @i_valor13		 descripcion = null,
   @i_valor14		 descripcion = null,
   @i_valor15		 descripcion = null,
   @i_valor16		 descripcion = null,
   @i_valor17		 descripcion = null,
   @i_valor18		 descripcion = null,
   @i_valor19		 descripcion = null,
   @i_valor20		 descripcion = null,
   @i_valor21		 descripcion = null,
   @i_valor22		 descripcion = null,
   @i_valor23		 descripcion = null,
   @i_valor24		 descripcion = null,
   @i_valor25		 descripcion = null,
   @i_valor26		 descripcion = null,
   @i_valor27		 descripcion = null,
   @i_valor28		 descripcion = null,
   @i_valor29		 descripcion = null,
   @i_valor30		 descripcion = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_tipo_custodia      descripcion,
   @w_item               tinyint,
   @w_nombre             descripcion,
   @w_detalle            descripcion,
   @w_tipo_dato          char(  1),
   @w_ultimo_item        tinyint,
   @w_error              int,
   @w_contador           tinyint,
   @w_mandatorio         char(1),
   @w_factura            char(1)


select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_item'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19110 and @i_operacion = 'I') or
   (@t_trn <> 19111 and @i_operacion = 'U') or
   (@t_trn <> 19112 and @i_operacion = 'D') or
   (@t_trn <> 19113 and @i_operacion = 'V') or
   (@t_trn <> 19114 and @i_operacion = 'S') or
   (@t_trn <> 19115 and @i_operacion = 'Q') or
   (@t_trn <> 19116 and @i_operacion = 'A') or
   (@t_trn <> 19117 and @i_operacion = 'B') or
   (@t_trn <> 19118 and @i_operacion = 'Z') or --MVI 10/16/96 Produbanco imp.
   (@t_trn <> 19119 and @i_operacion = 'O')    --MVI 10/16/96 Produbanco imp.
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
    select 
         @w_tipo_custodia = it_tipo_custodia,
         @w_item          = it_item,
         @w_nombre        = it_nombre,
         @w_detalle       = it_detalle,
         @w_tipo_dato     = it_tipo_dato,
         @w_mandatorio    = it_mandatorio,
         @w_factura       = isnull(it_factura,'N')
    from cob_custodia..cu_item
    where 
         it_tipo_custodia = @i_tipo_custodia and
         it_item = @i_item

    if @@rowcount > 0
            select @w_existe = 1
    else
            select @w_existe = 0
end

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if 
         @i_tipo_custodia = NULL or 
         @i_tipo_dato = NULL 
    begin
    /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end
end

/* Insercion del registro */
/**************************/

if @i_operacion = 'I'
begin
    if exists (select * from cu_item
                where it_tipo_custodia = @i_tipo_custodia and
                      it_nombre = @i_nombre) or @w_existe = 1
    begin
    /* Registro ya existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end


    begin tran
         select @w_ultimo_item = isnull(max(it_item),0)
         from cu_item
        where it_tipo_custodia = @i_tipo_custodia
         select @w_ultimo_item = @w_ultimo_item + 1
         insert into cu_item(
              it_tipo_custodia,
              it_item,
              it_nombre,
              it_detalle,
              it_tipo_dato,
              it_mandatorio,
              it_factura)
         values (
              @i_tipo_custodia,
              @w_ultimo_item,
              @i_nombre,
              @i_detalle,
              @i_tipo_dato,
              @i_mandatorio,
              @i_factura)

         if @@error <> 0 
         begin
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end
 
         select @w_ultimo_item

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_item
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_item',
         @i_tipo_custodia,
         @i_item,
         @i_nombre,
         @i_detalle,
         @i_tipo_dato,
         @i_mandatorio)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end 

         /* Insercion de elementos NULL para items existentes */

         insert into cu_item_custodia (
                ic_filial,
                ic_sucursal,
                ic_tipo_cust,
                ic_custodia,
                ic_item,
                ic_valor_item,
                ic_secuencial,
                ic_codigo_externo)
         select distinct 
                ic_filial,ic_sucursal,ic_tipo_cust,ic_custodia,
                @w_ultimo_item,'',ic_secuencial,ic_codigo_externo
         from   cu_item_custodia
         where  ic_tipo_cust = @i_tipo_custodia
 
    commit tran 
    return 0
end

/* Actualizacion del registro */
/******************************/

if @i_operacion = 'U'
begin
    if exists (select * from cu_item 
                where it_tipo_custodia = @i_tipo_custodia
                  and it_nombre = @i_nombre
                  and it_item <> @i_item)
    begin
    /* Registro ya existe */

        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901002
        return 1 
    end


    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */

        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    begin tran
         update cob_custodia..cu_item
         set 
              it_nombre     =  @i_nombre,
              it_detalle    =  @i_detalle,
              it_tipo_dato  =  @i_tipo_dato,
              it_mandatorio =  @i_mandatorio,
              it_factura    =  @i_factura
    where 
         it_tipo_custodia = @i_tipo_custodia and
         it_item = @i_item

         if @@error <> 0 
         begin
         /* Error en actualizacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
         end

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_item
         values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_item',
         @w_tipo_custodia,
         @w_item,
         @w_nombre,
         @w_detalle,
         @w_tipo_dato,
         @w_mandatorio)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end

            

         /* Transaccion de Servicio */
         /***************************/

         insert into ts_item
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_item',
         @i_tipo_custodia,


         @i_item,
         @i_nombre,
         @i_detalle,
         @i_tipo_dato,
         @i_mandatorio)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Eliminacion de registros */
/****************************/

if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
    /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

/***** Integridad Referencial *****/
/*****                        *****/
/* COMENTADO */
/*
   if exists (select * from cu_item_custodia
                     where ic_tipo_cust = @i_tipo_custodia
                       and ic_item = @i_item
                       and ic_valor_item <> "")
   begin
     select @w_error = 1907016
     goto error
   end 
*/
    begin tran
         delete cob_custodia..cu_item
    where 
         it_tipo_custodia = @i_tipo_custodia and
         it_item = @i_item

                          
         if @@error <> 0
         begin
         /*Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
         end

         delete cu_item_custodia 
         where ic_tipo_cust = @i_tipo_custodia
           and ic_item = @i_item


         /* Transaccion de Servicio */
         /***************************/

         insert into ts_item
         values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_item',
         @w_tipo_custodia,
         @w_item,
         @w_nombre,
         @w_detalle,
         @w_tipo_dato,
         @w_mandatorio)

         if @@error <> 0 
         begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end
    commit tran
    return 0
end

/* Consulta opcion QUERY */
/*************************/

if @i_operacion = 'Q'
begin
    if @w_existe = 1
       begin
         select 
              @w_tipo_custodia,
              @w_item,
              @w_nombre,
              @w_detalle,
              @w_tipo_dato,
              @w_mandatorio,
              @w_factura
         return 0
       end 
    else
    /* begin
    Registro no existe 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901005 */
    return 1 
end


if @i_operacion = 'A'
begin
      set rowcount 20
      if (@i_tipo_custodia is null and @i_item is null)
         select @i_tipo_custodia = @i_param1,
                @i_item = convert(tinyint,@i_param2)
      if @i_modo = 0 
      begin
         select "TIPO CUSTODIA" = it_tipo_custodia, "ITEM" = it_item,
                "NOMBRE" = it_nombre
           from cu_item with(index(cu_item_Key))
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901003
           return 1 
         end
      end
      else 
      begin
         select it_tipo_custodia, it_item, it_nombre
         from cu_item with(index(cu_item_Key))
         where ((it_tipo_custodia > @i_tipo_custodia) or
               (it_item > @i_item and it_tipo_custodia = @i_tipo_custodia))
         order by it_tipo_custodia, it_item --CSA Migracion Sybase
         if @@rowcount = 0
         begin
           exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1901004
           return 1 
         end
      end
end

if @i_operacion = 'S'
begin
      set rowcount 20
         select "ITEM"       = it_item,
                "NOMBRE"     = substring(it_nombre,1,30),
                "TIPO DATO"  = it_tipo_dato,
                "MANDATORIO" = it_mandatorio,
                "FACTURA"    = isnull(it_factura,'N')
         from cu_item with(index(cu_item_Key)) 
         where it_tipo_custodia = @i_tipo_custodia
           and (it_item > @i_item or @i_item is NULL)
         order by it_item

         if @@rowcount = 0
         begin
            if @i_item is NULL
            begin
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1901003
               return 1 
            end
            else
            /*begin
               exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1901004
               return 1 
            end */
            return 1
         end
end

if @i_operacion = 'B' -- BUSQUEDA CON CRITERIOS
begin
   
   select distinct "FILIAL"=cu_filial,
                   "SUCURSAL"=cu_sucursal,
                   "GARANTIA"=cu_custodia,
                   "DESCRIPCION"=substring(cu_descripcion,1,20),
                   "VALOR ACTUAL"=cu_valor_actual,
                   "MONEDA" = cu_moneda
   from cu_custodia,cu_item_custodia
   where cu_tipo        = @i_tipo_custodia
     and cu_filial      = ic_filial
     and cu_sucursal    = ic_sucursal
     and cu_tipo        = ic_tipo_cust
     and cu_custodia    = ic_custodia
     and (((ic_item     = @i_secuencial1 and ic_valor_item like @i_valor1)
          and @i_secuencial1 is not null)
      or ((ic_item      = @i_secuencial2 and ic_valor_item like @i_valor2)
          and @i_secuencial2 is not null)
      or ((ic_item      = @i_secuencial3 and ic_valor_item like @i_valor3)
          and @i_secuencial3 is not null)
      or ((ic_item      = @i_secuencial4 and ic_valor_item like @i_valor4)
          and @i_secuencial4 is not null)
      or ((ic_item      = @i_secuencial5 and ic_valor_item like @i_valor5)
          and @i_secuencial5 is not null)
      or ((ic_item      = @i_secuencial6 and ic_valor_item like @i_valor6)
          and @i_secuencial6 is not null)
      or ((ic_item      = @i_secuencial7 and ic_valor_item like @i_valor7)
          and @i_secuencial7 is not null)
      or ((ic_item      = @i_secuencial8 and ic_valor_item like @i_valor8)
          and @i_secuencial8 is not null)
      or ((ic_item      = @i_secuencial9 and ic_valor_item like @i_valor9)
          and @i_secuencial9 is not null)
      or ((ic_item      = @i_secuencial10 and ic_valor_item like @i_valor10)
          and @i_secuencial10 is not null)
      or ((ic_item      = @i_secuencial11 and ic_valor_item like @i_valor11)
          and @i_secuencial11 is not null)
      or ((ic_item      = @i_secuencial12 and ic_valor_item like @i_valor12)
          and @i_secuencial12 is not null)
      or ((ic_item      = @i_secuencial13 and ic_valor_item like @i_valor13)
          and @i_secuencial13 is not null)
      or ((ic_item      = @i_secuencial14 and ic_valor_item like @i_valor14)
          and @i_secuencial14 is not null)
      or ((ic_item      = @i_secuencial15 and ic_valor_item like @i_valor15)
          and @i_secuencial15 is not null)
      or ((ic_item      = @i_secuencial16 and ic_valor_item like @i_valor16)
          and @i_secuencial16 is not null)
      or ((ic_item      = @i_secuencial17 and ic_valor_item like @i_valor17)
          and @i_secuencial17 is not null)
      or ((ic_item      = @i_secuencial18 and ic_valor_item like @i_valor18)
          and @i_secuencial18 is not null)
      or ((ic_item      = @i_secuencial19 and ic_valor_item like @i_valor19)
          and @i_secuencial19 is not null)
      or ((ic_item      = @i_secuencial20 and ic_valor_item like @i_valor20)
          and @i_secuencial20 is not null)
      or ((ic_item      = @i_secuencial21 and ic_valor_item like @i_valor21)
          and @i_secuencial21 is not null)
      or ((ic_item      = @i_secuencial22 and ic_valor_item like @i_valor22)
          and @i_secuencial22 is not null)
      or ((ic_item      = @i_secuencial23 and ic_valor_item like @i_valor23)
          and @i_secuencial23 is not null)
      or ((ic_item      = @i_secuencial24 and ic_valor_item like @i_valor24)
          and @i_secuencial24 is not null)
      or ((ic_item      = @i_secuencial25 and ic_valor_item like @i_valor25)
          and @i_secuencial25 is not null)
      or ((ic_item      = @i_secuencial26 and ic_valor_item like @i_valor26)
          and @i_secuencial26 is not null)
      or ((ic_item      = @i_secuencial27 and ic_valor_item like @i_valor27)
          and @i_secuencial27 is not null)
      or ((ic_item      = @i_secuencial28 and ic_valor_item like @i_valor28)
          and @i_secuencial28 is not null)
      or ((ic_item      = @i_secuencial29 and ic_valor_item like @i_valor29)
          and @i_secuencial29 is not null)
      or ((ic_item      = @i_secuencial30 and ic_valor_item like @i_valor30)
          and @i_secuencial30 is not null))
     and ( (cu_filial > @i_filial or
          (cu_filial = @i_filial and cu_sucursal > @i_sucursal) or
          (cu_filial = @i_filial and cu_sucursal = @i_sucursal and cu_custodia > @i_custodia)) or @i_filial is null)
   order by cu_filial,cu_sucursal,cu_custodia
   if @@rowcount = 0
   begin 
      if @i_filial is null
      begin
         select @w_error = 1901003        
         goto error
      end else
      begin
         select @w_error = 1901004
         goto error
      end   
   end
end

if @i_operacion = 'Z'
begin
     select it_item,it_nombre,ic_valor_item
     from cu_item,cu_item_custodia
     where it_tipo_custodia = @i_tipo_custodia
       and ic_tipo_cust     = @i_tipo_custodia
       and ic_filial        = @i_filial
       and ic_sucursal      = @i_sucursal
       and ic_custodia      = @i_custodia
       and ic_item          = it_item
     order by ic_secuencial
end

if @i_operacion = 'O'
begin
     select tr_numero_op_banco
     from cu_custodia,cob_credito..cr_gar_propuesta,cob_credito..cr_tramite
     where cu_filial     = @i_filial
       and cu_sucursal   = @i_sucursal
       and cu_tipo       = @i_tipo_custodia
       and cu_custodia   = @i_custodia
       and gp_garantia   = cu_codigo_externo
       and gp_tramite    = tr_tramite 
end

return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1
go