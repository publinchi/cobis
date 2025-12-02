/************************************************************************/
/*   Archivo:             ccobis.sp                                     */
/*   Stored procedure:    sp_cuenta_cobis                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Fabian de la Torre, Rodrigo Garces            */
/*   Fecha de escritura:  Ene. 1998                                     */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                         PROPOSITO                                    */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   H: Ayuda de las cuentas del producto respectivo                    */
/*   V: Validacion de que la cuenta dada exista                         */
/*        FECHA      AUTOR      RAZON                                   */
/*      Feb   2001      E.Pelaez        Interfaz ACH                    */
/*      Feb 14/2002     E.Laguna        Desarrollos ACH  -- ELA ACH     */
/*      Abr 2007        E.Pelaez        NR-244 BAC                      */
/*   23/abr/2010        Fdo Carvajal Revision Interfaz Ahorros-CCA      */
/*   14/Dic/2010        J. Ardila       REQ 205. Debito Automatico      */
/*   19/Abr/2011        SMolano         Filtrar cuentas de Ahorro       */
/*                                      Contratual(no se presentan      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuenta_cobis')
   drop proc sp_cuenta_cobis
go
--- INC. 114944 MAR.03.2014
create proc sp_cuenta_cobis
@i_operacion             char(1)     = NULL,
@i_cliente               int         = 0,
@i_cliente_ali           int         = 0,
@i_producto              catalogo    = NULL,
@i_cuenta                varchar(20) = NULL,
@i_banco                 varchar(24) = NULL,
@i_categoria_fpago       catalogo    = NULL,
@i_ced_ruc               varchar(15) = NULL,
@i_catalogo_banco_ach    varchar(13) = NULL,
@i_oficina		         smallint    = NULL

as declare 
@w_sp_name               descripcion,
@w_operacionca           int,
@w_moneda                smallint,
@w_error                 int,
@w_num_dec               tinyint,
@w_pcobis                tinyint,
@w_categoria             catalogo,
@w_tipo_cuenta           char(2),
@w_nombre                varchar(50),
@w_forma_des             varchar(10),
@w_prod_banc             int

select @w_sp_name = 'sp_cuenta_cobis'

/*DATOS DEL PRODUCTO*/
select 
@w_pcobis    = cp_pcobis,
@w_moneda    = cp_moneda,
@w_categoria = cp_categoria
from ca_producto
where cp_producto = @i_producto 
                                                                                      

/*NOMBRE DEL CLIENTE*/
if @i_operacion = 'N' begin
   select  en_nomlar
   from   cobis..cl_ente with (nolock)
   where  en_ente = @i_cliente
end

if @i_cuenta is null select @i_cuenta =  '0'

select @w_prod_banc = C.codigo 
from cobis..cl_tabla T, cobis..cl_catalogo C 
where T.tabla = 're_pro_banc_cb'
and   T.codigo = C.tabla
and   C.estado = 'V'

-- Detecta si envian el op_banco o el op_operacion y calcula el op_banco
if @i_operacion in ( 'H', 'V' )  and @i_banco is not null begin
   if isnumeric ( @i_banco ) = 1 
   begin 
      if len(@i_banco) < 9
      begin
         select @w_operacionca = convert( int, @i_banco ) 
         select @i_banco = op_banco from cob_cartera..ca_operacion with (nolock) where op_operacion = @w_operacionca 
      end
   end 
end


if @i_operacion = 'H' begin
   if @w_pcobis in (3,248)  --- CUENTAS CORRIENTES 
   begin
        exec cob_interface..sp_cta_cobis_interfase
        @i_operacion     = 'op3',
        @i_producto      = @w_pcobis,
        @i_cuenta        = @i_cuenta,
        @i_moneda        = @w_moneda,
        @i_cliente       = @i_cliente
   end
   
   if @w_pcobis in (4,249)
   begin
       exec cob_interface..sp_cta_cobis_interfase
        @i_operacion     = 'op1',
        @i_producto      = @w_pcobis,
        @i_cuenta        = @i_cuenta,
        @i_moneda        = @w_moneda,
        @i_cliente       = @i_cliente,
        @i_prod_bancario = @w_prod_banc
   end
      
   if @w_pcobis = 7
   begin
      set rowcount 20
      select 
      'Cuenta'  = op_banco,
      'Cliente' = op_cliente,
      'Nombre'  = op_nombre
      from  ca_operacion with (nolock)
      where op_cliente = @i_cliente
      and   op_moneda  = @w_moneda
      and   op_estado  = 1  
      order by op_banco  
      set rowcount 0  
   end  
end

if @i_operacion = 'V' begin
   if @w_pcobis in (3,248) begin  --- CUENTAS CORRIENTES 
      begin 
      exec cob_interface..sp_cta_cobis_interfase
      @i_operacion     = 'op5',
      @i_producto      = @w_pcobis,
      @i_cuenta        = @i_cuenta,
      @i_moneda        = @w_moneda,
      @i_cliente       = @i_cliente
      end 
   end 

   if @w_pcobis in (4,249) begin   --- CUENTAS DE AHORROS
      begin
        exec cob_interface..sp_cta_cobis_interfase
        @i_operacion     = 'op6',
        @i_producto      = @w_pcobis,
        @i_prod_bancario = @w_prod_banc,
        @i_cuenta        = @i_cuenta,
        @i_moneda        = @w_moneda,
        @i_cliente       = @i_cliente
      end
   end
   
   if @w_pcobis =7   begin  --- PAGO EN CARTERA 
      if not exists 
         (select 1 
          from  ca_operacion with (nolock)
          where op_banco   = @i_cuenta ) begin
          
         select @w_error = 710022
         goto ERROR
      end
   end 

   if @w_pcobis = 9 begin
      --- COMERCIO EXTERIOR 
      select @w_error = 710206
      goto ERROR
   end
                               
end 


if @i_operacion = 'C' begin --CUENTA CHEQUE DE GERENCIA
   begin
    exec cob_interface..sp_cta_cobis_interfase
    @i_operacion     = 'op2',
    @i_producto      = @w_pcobis,
    @i_oficina       = @i_oficina
   end
end

if @i_operacion = 'A' begin --MARCA PARA SABER SI SE CREA ALTERNA

   if exists (select 1 from cobis..cl_catalogo with (nolock)
   where tabla = (select codigo from cobis..cl_tabla with (nolock)
                  where tabla = 'ca_especiales')
   and   codigo = @i_producto)
	begin  
    select 'S'
	end
	else
	begin
     select 'N'
	end
end

return 0 


ERROR:
exec cobis..sp_cerror 
@t_debug  =  'N',
@t_file   =  null,  
@t_from   =  @w_sp_name,
@i_num    =  @w_error
return @w_error
go

