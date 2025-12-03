/*************************************************************************/
/*   Archivo:              cancelacca.sp                                 */
/*   Stored procedure:     sp_cancelacca                                 */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
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
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_cancelacca') IS NOT NULL
    DROP PROCEDURE dbo.sp_cancelacca
go

create proc dbo.sp_cancelacca 
(  @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_ofi                smallint  = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @s_user               login    = null,
   @i_tramite		 int = null,
   @i_operacion          char(1) = 'I',
   @i_login		 login = null,
   @i_secuencial_pag	 int = null)
as

declare
   @w_today             datetime,     	
   @w_return            int,          	
   @w_sp_name           varchar(32),  	
   @w_garantia          varchar(64),
   @w_status            int,
   @w_estado 		catalogo,
   @w_moneda 		tinyint,
   @w_valor_actual 	money,
   @w_abierta_cerrada 	char (1),
   @w_abi_cer		char (1),
   @w_oficina 		smallint,
   @w_ofi_contabiliza 	smallint,
   @w_filial		tinyint,
   @w_sucursal 		smallint,
   @w_tipo_cust		varchar(64),
   @w_custodia 		int,
   @w_contabilizar 	char(1),
   @w_est_can 		int,
   @w_abierta           char(1),
   @w_tabla_prod        smallint ---GCR

select @w_today   = @s_date
select @w_sp_name = 'sp_cancelacca',
       @s_user    = isnull(@s_user,suser_name())
select @i_login   = isnull(@i_login,@s_user)

select @w_est_can = pa_tinyint from cobis..cl_parametro
where pa_nemonico = 'ESTCAN'
and pa_producto = 'CRE'
/* VALIDACION DE CAMPOS NULOS */
/******************************/

if @i_tramite = NULL return 0
if @i_login = NULL return 2101001

insert into #garantias 
select gp_tramite, gp_garantia, gp_est_garantia
from   cob_credito..cr_gar_propuesta, 
       cob_custodia..cu_custodia   -- PSE 08/SEP/2007
where  gp_garantia = cu_codigo_externo	-- PSE 08/SEP/2007
  and gp_tramite  = @i_tramite 
  --and gp_est_garantia = 'V'		-- PSE 08/SEP/2007

if @@rowcount = 0  return 0


/* CON EL TRAMITE DE INGRESO BUSCAR LAS GARANTIAS VIGENTES ASOCIADAS  */
/* A LA OPERACION DE CCA*/


if @i_operacion = 'I' begin

--   declare cur_garantias insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
   declare cur_garantias cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
   select  garantia
   from    #garantias
   where   estado = 'V'

   open cur_garantias
   fetch cur_garantias into @w_garantia

   if @@FETCH_STATUS = -1 return 0

   while @@FETCH_STATUS != -1

   begin
   /* VERIFICAR SI GARANTIA ESTA RESPALDANDO A OTRAS OPERACIONES DE CCA*/

/*   if exists(select 1 from cob_credito..cr_gar_propuesta
	   where gp_garantia = @w_garantia
	   and gp_est_garantia = 'V'
	   and gp_tramite <> @i_tramite)
*/
-- PGA Para que cancele garantias que estaban amparando 
--a otras operaciones que ya estaban canceladas

--if exists(select 1 from cob_credito..cr_gar_propuesta,cob_cartera..ca_operacion
/*if not exists(select 1 from cob_credito..cr_gar_propuesta,cob_cartera..ca_operacion
	   where gp_garantia = @w_garantia
	   and gp_est_garantia = 'V'
	   and gp_tramite <> @i_tramite
	   and gp_tramite = op_tramite
	   and op_estado <> @w_est_can)*/

--     return 0
if not exists(select 1 from cob_custodia..cu_custodia where cu_abierta_cerrada='A' and cu_codigo_externo=@w_garantia)
   begin  --Inicio control de existencias de otras operaciones
    exec @w_status = sp_compuesto
	@t_trn = 19245,
	@i_operacion = 'Q',
	@i_compuesto = @w_garantia,
	@o_filial = @w_filial out,
	@o_sucursal = @w_sucursal out,
	@o_tipo = @w_tipo_cust out,
	@o_custodia = @w_custodia out
	    
	if @w_status <> 0  return 1901213

   select
        @w_estado = cu_estado,
	@w_moneda = cu_moneda,
	@w_valor_actual = cu_valor_actual,
	@w_abierta_cerrada = cu_abierta_cerrada,
	@w_oficina = cu_oficina,
	@w_ofi_contabiliza = cu_oficina_contabiliza
   from cu_custodia
   where  cu_codigo_externo = @w_garantia

   select @w_valor_actual = isnull(@w_valor_actual, 0)

   if exists( SELECT * FROM cu_por_inspeccionar
		WHERE pi_codigo_externo = @w_garantia)
   delete cu_por_inspeccionar
   where pi_codigo_externo = @w_garantia

   exec @w_status = sp_transaccion
   @s_ssn = @s_ssn,
   @s_ofi = @s_ofi,           
   @s_date = @s_date,
   @t_trn = 19000,
   @i_operacion = 'I',
   @i_filial = @w_filial,
   @i_sucursal = @w_sucursal,
   @i_tipo_cust = @w_tipo_cust,
   @i_custodia = @w_custodia,
   @i_fecha_tran = @w_today,
   @i_debcred = 'D',
   @i_valor = @w_valor_actual,
   @i_descripcion = 'CANCELACION DE LA GARANTIA',
   @i_usuario = @i_login,
   @i_cancelacion = 'S'
   
   if @w_status <> 0 return 1901013


   select @w_contabilizar = tc_contabilizar
   from   cu_tipo_custodia
   where tc_tipo = @w_tipo_cust

   if  @w_contabilizar = 'S'
   begin
   /*TRANSACCION CONTABLE*/
    exec @w_return = sp_conta
      @t_trn = 19300,
      @s_date = @s_date,      
      @i_operacion = 'I',
      @i_filial = @w_filial,
      @i_oficina_orig = @w_ofi_contabiliza,
      @i_oficina_dest = @w_ofi_contabiliza,
      @i_tipo = @w_tipo_cust,
      @i_moneda = @w_moneda,
      @i_valor = @w_valor_actual,
      @i_operac = 'E',
      @i_signo =1,
      @i_codigo_externo = @w_garantia

      if @w_return <> 0 return 1901013
    end
   
    update cu_custodia
    set cu_estado = 'C',
        cu_fecha_modif = @s_date,
        cu_fecha_modificacion = @s_date,
        cu_usuario_modifica = @i_login
    where cu_codigo_externo = @w_garantia

    ---GCR: Act.Documentos a devueltos
    ----------------------------------
    update cu_vencimiento
       set ve_estado = 'D' ---Devuelto por Canc. de Garantia
     where ve_codigo_externo = @w_garantia
       and ve_estado = 'T' --- Pendiente de Cobro

    update cob_credito..cr_gar_propuesta
    set gp_est_garantia = 'C'
    where gp_garantia = @w_garantia
   
   /*********************************************
   FAndrade 12/08/2008
   Cancela las pólizas asociadas a las garantías
   *********************************************/
   --Inicio
	
   exec @w_status = cob_custodia..sp_poliza_depreciacion
   	@s_ssn               	= @s_ssn,
	@s_date               	= @s_date,
	@s_ofi			= @s_ofi,
   	@s_user	       		= @s_user,
   	@t_trn			= 19766,
   	@i_filial		= @w_filial,
   	@i_sucursal 		= @w_sucursal,
	@i_tipo			= @w_tipo_cust,
	@i_custodia		= @w_custodia,
   	@i_operacion		= 'C',
   	@i_codigo_externo	= @w_garantia,
   	@i_secuencial_pag	= @i_secuencial_pag
   
   if @w_status <> 0 return 1901013
   
   --Fin
   
   end  --Fin de control de existencias
   fetch cur_garantias into @w_garantia
   end

   close cur_garantias
   deallocate cur_garantias

end

if @i_operacion = 'R' begin

   declare cur_garantias insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
   select garantia 
     from #garantias g
    where estado  = 'C'
      --II LRC 06/15/2010
      and exists (select 1 from cob_custodia..cu_transaccion 
                   where tr_codigo_externo = g.garantia
                     and tr_descripcion = 'CANCELACION DE LA GARANTIA'
                     and tr_transaccion = (select max(tr_transaccion)
                                             from cob_custodia..cu_transaccion
                                            where tr_codigo_externo = g.garantia
                                              and tr_descripcion like 'CANCELACION DE LA GARANTIA%')
                  )
      --FI LRC 06/15/2010
---   and     gp_abierta = 'C'

   open  cur_garantias
   fetch cur_garantias into @w_garantia

   if @@FETCH_STATUS = -1 return 0

   while @@FETCH_STATUS != -1
   begin
      select
            @w_estado          = cu_estado,
            @w_moneda          = cu_moneda,
            @w_valor_actual    = cu_valor_actual,
            @w_abierta_cerrada = cu_abierta_cerrada,
            @w_oficina         = cu_oficina,
            @w_ofi_contabiliza = cu_oficina_contabiliza,
            @w_tipo_cust       = cu_tipo,
            @w_filial          = cu_filial,
            @w_sucursal	       = cu_sucursal,
            @w_custodia	       = cu_custodia,
            @w_abierta         = cu_abierta_cerrada
      from cu_custodia
      where  cu_codigo_externo = @w_garantia 
      and    cu_estado         = 'C'
     
      if @@rowcount = 0  goto NEXT
      
      if @w_abierta = 'A' goto NEXT

      select @w_contabilizar = tc_contabilizar
             from cu_tipo_custodia
             where tc_tipo = @w_tipo_cust 

      select @w_valor_actual = th_valor
      from   cu_tran_conta_his a
      where  th_codigo_externo = @w_garantia
      and    th_operacion      = 'E'
      --II LRC 06.14.2010 
      --having th_secuencial = max(th_secuencial) --devolvia valor de cualquier garantia
      and    th_secuencial = (select max(th_secuencial) 
                                from cob_custodia..cu_tran_conta_his b
                               where b.th_codigo_externo = a.th_codigo_externo
                                 and b.th_operacion      = 'E')
      --FI LRC 06.14.2010 
      

      if @w_contabilizar = 'S' and isnull(@w_valor_actual,0) <> 0
      begin
           --  TRANSACCION CONTABLE
           exec @w_status = sp_conta
           @s_ssn  = @s_ssn,
           @s_date = @s_date,
           @t_trn  = 19300,
           @i_operacion = 'I',
           @i_filial = @w_filial,
           @i_oficina_orig = @w_ofi_contabiliza,
           @i_oficina_dest = @w_ofi_contabiliza,
           @i_tipo = @w_tipo_cust,
           @i_moneda = @w_moneda,
           @i_valor = @w_valor_actual,
           @i_operac = 'I',
           @i_signo = 1,
           @i_codigo_externo = @w_garantia
         
           if @w_status <> 0 return 1901013
      end

      update cu_custodia
      set    cu_estado = 'V',
             cu_valor_actual = @w_valor_actual
      where  cu_codigo_externo = @w_garantia

      ---GCR: Act.Documentos a devueltos
      ----------------------------------
      update cu_vencimiento
         set ve_estado = 'T' --- Pendiente de Cobro 
       where ve_codigo_externo = @w_garantia
         and ve_estado = 'D' ---Devuelto por Canc. de Garantia 

      update cob_credito..cr_gar_propuesta
      set    gp_est_garantia = 'V'
      where  gp_tramite = @i_tramite
      and    gp_garantia = @w_garantia
      
      	/*********************************************
	 FAndrade 12/08/2008
	 Cancela las pólizas asociadas a las garantías
	 *********************************************/
	 --Inicio

	exec @w_status = cob_custodia..sp_poliza_depreciacion
	@s_ssn               	= @s_ssn,
	@s_date               	= @s_date,
   	@s_ofi			= @s_ofi,
   	@s_user	       		= @s_user,
	@t_trn			= 19766,
	@i_filial		= @w_filial,
	@i_sucursal 		= @w_sucursal,
	@i_tipo			= @w_tipo_cust,
	@i_custodia		= @w_custodia,
	@i_operacion		= 'R',
	@i_codigo_externo	= @w_garantia,
	@i_secuencial_pag	= @i_secuencial_pag

	if @w_status <> 0 return 1901013
         
   	--Fin

   NEXT:
   fetch cur_garantias into @w_garantia
   end 
   close cur_garantias
   deallocate cur_garantias

end
return 0
go