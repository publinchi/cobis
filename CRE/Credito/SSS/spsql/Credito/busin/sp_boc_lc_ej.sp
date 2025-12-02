/********************************************************************/
/*   NOMBRE LOGICO:         sp_boc_lc_ej                            */
/*   NOMBRE FISICO:         sp_boc_lc_ej.sp                         */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          COB                                     */
/*   FECHA DE ESCRITURA:    23-Feb-2022                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Balance Operativo Contable de Líneas de Crédito                */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   23-Feb-2022        COB.               Emision Inicial          */
/*   16-Ago-2023        P. Jarrin.         Ajuste - B885692         */
/********************************************************************/

use cob_credito
go

if exists(select * from sysobjects where name = 'sp_boc_lc_ej')
   drop proc sp_boc_lc_ej
go

create proc sp_boc_lc_ej(
   @s_ssn             int           = null,
   @s_date            datetime      = null,
   @s_user            login         = null,
   @s_term            descripcion   = null,
   @s_corr            char(1)       = null,
   @s_ssn_corr        int           = null,
   @s_ofi             smallint      = null,
   @s_culture         varchar(10)   = null,
   @t_rty             char(1)       = null,
   @t_trn             int           = null,
   @t_debug           char(1)       = 'N',
   @t_file            varchar(14)   = null,
   @t_from            varchar(30)   = null,
   @t_show_version    bit           = 0,
   @i_filial          tinyint       = 1,
   @i_fecha           datetime      = null,
   @i_sarta           int           = 21000,
   @i_batch           int           = 21002,
   @i_secuencial      int           = null,
   @i_corrida         int           = null,
   @i_intento         int           = null
)

as 
declare @w_error              int,
        @w_return             int,
        @w_sp_name            descripcion,
        @w_mensaje            varchar(255),
        @w_cliente            int,
        @w_codvalor           varchar(20),
        @w_dp_cuenta          varchar(40),
        @w_estado             catalogo,
        @w_moneda             tinyint,
        @w_cuenta_final       varchar(20),
        @w_saldo              money,
        @w_debitos            money,
        @w_creditos           money,
        @w_oficina_conta      int,
        @w_oficina            int,
        @w_moneda_nacional    smallint,
        @w_num_dec            tinyint,
        @w_area_cont          smallint,
        @w_boc                catalogo,
        @w_numero_linea       varchar(30),
        @w_valor              money,  
        @w_tipo               catalogo,
        @w_val_opera_mn       money,
        @w_val_opera_me       money,
        @w_pgroup             int,
        @w_sig                char(1),
        @w_numero             int,
        @w_estado_vig         catalogo,
        @w_reg_det            char(1),
        @w_param              varchar(15),
        @w_tparametro         varchar(20),
        @w_clase              catalogo,
        @w_tipolin            char(1),
        @w_dfondos            varchar(5),
        @w_relacionado        char(1),
        @w_dp_cuenta_val      int

---- VERSIONAMIENTO DEL PROGRAMA ----

if @t_show_version = 1
begin
   print 'Stored procedure sp_boc, Version 4.0.0.1'
   return  0
end

if @s_culture is null
begin
   exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out
end

select @w_sig ='N',
       @w_reg_det ='N',
       @w_sp_name = 'sp_boc_lc_ej.sp',
       @w_dp_cuenta_val = 1

---REGISTRA EL DETALLE DEL BOC
select @w_reg_det = pa_char  
from cobis..cl_parametro
where pa_producto = 'CRE'
and   pa_nemonico ='DETBOC'

--- MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_estado_vig = pa_char
from cobis..cl_parametro
where pa_producto = 'CRE'
and pa_nemonico = 'EVIGLN'

--PARAMETRO BOC DE CREDITO
select @w_boc = pa_char
from cobis..cl_parametro 
where pa_producto ='CRE'
and   pa_nemonico ='CRBOC'
if @@rowcount = 0 
begin
   select @w_error = 2110247
   goto ERROR
end

if isnull(@i_fecha,'') = ''
begin
   select @i_fecha = isnull(fp_fecha, getdate())
   from cobis..ba_fecha_proceso
end

--PARAMETRO AREA CONTABLE
select @w_area_cont = isnull(pa_tinyint, pa_smallint)
from cobis..cl_parametro 
where pa_producto ='CRE'
and   pa_nemonico ='CAORC'
if @@rowcount = 0 
begin
   select @w_error   = 2110248
   goto ERROR
end

-- VERIFICAR QUE EXISTA PERFIL DEL BOC 
if not exists (select 1 from   cob_conta..cb_perfil
               where  pe_producto = 21
               and    pe_perfil   = @w_boc
               and    pe_empresa  = @i_filial)
begin
   select @w_error   = 2110249
   goto ERROR
end

--INICIALIZAR TABLAS DEL BOC 
delete cr_boc_operaciones

delete cob_conta_his..cb_hist_boc_det
where hbd_fecha = @i_fecha
and hbd_empresa = @i_filial
and hbd_producto = 21

---Borra registros de la tabla cob_conta..cb_boc
exec @w_return = cob_conta..sp_ing_opera  
     @t_trn       = 6064,
     @i_operacion = 'D',
     @i_empresa   = @i_filial,
     @i_producto  = 21,
     @i_fecha     = @i_fecha
if @w_return <> 0
begin 
   select @w_error   = 2110250
   goto ERROR
end

--Insercion de Lineas
insert into cr_boc_operaciones(
bo_num_linea,    bo_oficina,     bo_cliente ,
bo_valor,        
bo_estado,       bo_tipo,        bo_moneda,      
bo_codigo_valor, bo_empresa,     bo_grupo,
bo_cod_linea,    bo_clase,       bo_tipolin,
bo_dfondos,      bo_relacionado)
select 
li_num_banco,    li_oficina,     li_cliente,
valor = round(li_monto-isnull(li_utilizado,0),2),
li_estado,       rtrim(ltrim(li_tipo)),        li_moneda,
'1',             @i_filial,      li_grupo,
li_numero,       tr_toperacion,  case  when li_tipo = 'LCR' then rtrim(ltrim(li_rotativa)) when li_tipo = 'LTC' then 'V' end, -- li_revolvente,
null,   'N'
from cr_linea, cr_tramite
where li_estado  = @w_estado_vig
and   li_tramite = tr_tramite

if @@error <> 0
begin
   select @w_error   = 2103001
   goto ERROR
end

--CURSOR PARA LECTURA DE LINEAS
declare cursor_datos 
cursor for select
      bo_num_linea,     bo_oficina,        bo_cliente ,
      bo_valor,         bo_estado,         bo_tipo,       
      bo_codigo_valor,  bo_moneda,         bo_grupo,
      bo_cod_linea,     bo_clase,          bo_tipolin,        
      bo_dfondos,       bo_relacionado
from cr_boc_operaciones
where bo_empresa = @i_filial
and   bo_valor   > 0
open  cursor_datos
fetch cursor_datos 
into  @w_numero_linea,  @w_oficina,    @w_cliente,       
      @w_valor,         @w_estado,     @w_tipo,       
      @w_codvalor,      @w_moneda,     @w_pgroup,
      @w_numero,        @w_clase,      @w_tipolin,    
      @w_dfondos,       @w_relacionado

while @@fetch_status = 0
begin
   select @w_sig = 'S',
          @w_oficina_conta = 0

   --VERIFICA SI EXISTE DETALLE PARA EL PERFIL DADO
   if not exists (select 1  from   cob_conta..cb_det_perfil
                  where  dp_empresa  = @i_filial
                  and    dp_producto = 21
                  and    dp_perfil   = @w_boc
                  and    dp_codval   = @w_codvalor)
   begin
      select @w_error   = 2110251--ERROR: No existe Detalle de Perfil para el perfil y codigo valor asignado 
      goto ERROR
   end
   
   --ACTUALIZO LAS LINEAS CON LA OFICINA CONTABLE CORRESPONDIENTE
   select @w_oficina_conta =  re_ofconta 
   from cob_conta..cb_relofi
   where  re_ofadmin = @w_oficina
   if @@rowcount = 0
   begin
      select @w_error   = 1901003
      goto ERROR
   end

   begin tran
   --CURSOR PARA LA LECTURA DE LOS PERFILES
   declare cursor_perfiles cursor for 
   select dp_cuenta, isnumeric(dp_cuenta)
   from   cob_conta..cb_det_perfil
   where dp_empresa  = @i_filial
   and   dp_producto = 21
   and   dp_perfil   = @w_boc
   and   dp_codval   = @w_codvalor
   open  cursor_perfiles
   fetch cursor_perfiles
   into  @w_dp_cuenta, @w_dp_cuenta_val

   while @@fetch_status = 0
   begin
      -- INICIALIZAR VARIABLE
      select @w_cuenta_final = '',
             @w_mensaje      = '',
             @w_param        = '',
             @w_tparametro   = ''

      if (@w_dp_cuenta_val = 0)
      begin
          select distinct 
            @w_param      = pa_parametro, 
            @w_tparametro = pa_stored
          from   cob_conta..cb_parametro 
          where pa_parametro = @w_dp_cuenta   
          if @@error <> 0 
          begin
             select @w_error = 2103001
             close cursor_perfiles 
             deallocate cursor_perfiles 
             goto ERROR
          end

          if not exists(select 1 from  cob_conta..cb_relparam
                        where re_parametro = @w_param
                        and   re_clave   = @w_moneda
                        and   re_empresa  = @i_filial)
          begin
             select @w_error    = 2110244
             close cursor_perfiles 
             deallocate cursor_perfiles 
             goto ERROR   
          end

          select @w_cuenta_final = isnull(re_substring,@w_dp_cuenta)
          from  cob_conta..cb_relparam
          where re_parametro = @w_param
          and   re_clave   = @w_moneda
          and   re_empresa  = @i_filial      
      end 
    
      if @w_cuenta_final = ''
       select @w_cuenta_final = @w_dp_cuenta
    
      if not exists (select 1 from  cob_conta..cb_cuenta
                     where cu_empresa = @i_filial
                     and   cu_cuenta  = @w_cuenta_final
                     and   cu_movimiento ='S')
      begin     
         select @w_error     = 2110244 ---No existe cuenta
         close cursor_perfiles 
         deallocate cursor_perfiles 
         goto ERROR
      end
   
      select @w_val_opera_mn = 0,
             @w_val_opera_me = 0

      if @w_moneda_nacional = @w_moneda
         select @w_val_opera_mn = round(@w_valor,2)
      else
      begin
         select @w_val_opera_mn = round(@w_valor * ct_valor,2) 
         from cob_credito..cb_cotizaciones
         where ct_moneda = @w_moneda 
 
         select @w_val_opera_me = round(@w_valor,2)
      end
               
      --REGISTRA DATOS DEL BOC
      exec @w_return = cob_conta..sp_ing_opera
           @t_trn            = 6063,
           @i_operacion      = 'I',
           @i_empresa        = @i_filial,
           @i_producto       = 21,
           @i_fecha          = @i_fecha,
           @i_cuenta         = @w_cuenta_final,
           @i_oficina        = @w_oficina_conta,
           @i_area           = @w_area_cont,
           @i_moneda         = @w_moneda,
           @i_val_opera_mn   = @w_val_opera_mn,
           @i_val_opera_me   = @w_val_opera_me
      if @w_return != 0
      begin
         select @w_error   = @w_return
         close cursor_perfiles 
         deallocate cursor_perfiles
         goto ERROR
      end

      fetch cursor_perfiles  into  @w_dp_cuenta, @w_dp_cuenta_val
   end
   close cursor_perfiles 
   deallocate cursor_perfiles 

   if @w_reg_det ='S'
   begin
      insert into cob_conta_his..cb_hist_boc_det       
      (hbd_empresa,     hbd_producto,            hbd_fecha,         hbd_cuenta,
       hbd_oficina,     hbd_area,                hbd_operacion,     hbd_adicional,
       hbd_moneda,      hbd_val_opera_mn,        hbd_val_opera_me,  hbd_val_conta_mn,
       hbd_val_conta_me)           
      values (
       @i_filial,       21,                      @i_fecha,          @w_cuenta_final,
       @w_oficina_conta,@w_area_cont,            @w_numero_linea,   '',
       @w_moneda,       @w_val_opera_mn,         @w_val_opera_me,   @w_val_opera_mn,     
       @w_val_opera_me)       
      if @@error <> 0
      begin
         select @w_error   = 2110252
         close cursor_datos
         deallocate cursor_datos
         goto ERROR
      end          
   end

   commit tran

   fetch next from cursor_datos 
   into  @w_numero_linea,  @w_oficina,    @w_cliente,       
         @w_valor,         @w_estado,     @w_tipo,   
         @w_codvalor,      @w_moneda,     @w_pgroup,
         @w_numero,        @w_clase,      @w_tipolin,    
         @w_dfondos,       @w_relacionado
end
close cursor_datos
deallocate cursor_datos

return 0

ERROR:
   exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = @w_error,
      @s_culture  = @s_culture
   return @w_error

go
