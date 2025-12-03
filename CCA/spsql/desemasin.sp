/******************************************************************/
/*  Archivo:            desemasin.sp                              */
/*  Stored procedure:   sp_desembolso_asincrono                   */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 17-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  17/Jun/19        Lorena Regalado    Proceso asincrono de      */
/*                                      Desembolsos               */
/*  15/Jul/19        Adriana Giler      Desembolso Renovacion TEC */
/*  25/Jul/19        Adriana Giler      Incentivos Grupales       */
/*  16/Abr/21        Kevin Rodríguez    Administración individual S,*/
/*                                      No validación de ahorro   */
/*                                      mínimo                    */
/******************************************************************/


use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_desembolso_asincrono')
   drop proc sp_desembolso_asincrono
go

create proc sp_desembolso_asincrono
     @s_srv              varchar(30)    = null,
     @s_ssn              int            = null,
     @s_user             login          = null,
     @s_term             varchar(30)    = null,
     @s_date             datetime       = null,
     @s_ofi              smallint       = null,
     @t_trn              int            = 77506

            

as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_return               int,
   @w_tipo_operacion       varchar(10),
   @w_oficina              smallint,
   @w_toperacion           varchar(10),
   @w_destino              varchar(10),
   @w_fecha_desemb         datetime,
   @w_moneda               tinyint,
   @w_monto                money,
   @w_plazo                smallint,
   @w_frecuencia           varchar(10),
   @w_tasa                 float,
   @w_fecha_primer_pago    datetime,
   @w_otros                varchar(255),
   @w_grupo                int,
   @w_cliente              int,
   @w_monto_ahorro         money,
   @w_codeudor             int,
   @w_oficial              smallint,
   @w_monto_hijas          money,
   @w_operacion            int,
   @w_banco                cuenta,
   @w_tramite              int,
   @w_ciclo                int,
   @w_msg                  varchar(64),
   @w_mensaje              varchar(250),
   @w_fecha_creacion       VARCHAR(10),
   @w_commit               char(1),
   @w_presi_grp            int,
   @w_cuenta_gr            cuenta,
   @w_fecha_proceso        datetime,
   @w_fecha_ini            datetime,
   @w_cta_grupal           cuenta ,
   @w_cumple_ahorro        char(1),
   @w_sesn                 int,
   @w_ssn                  int,
   @w_op_forma_pago        catalogo,
   @w_rowcount             int,
   @w_secuencial           int,
   @w_admin_individual     char(1),
   @w_msj_er               varchar(264),
   @w_es_interciclo        char(1),
   @w_ref_grupal           cuenta,
   @w_op_grupal            int,
   @w_tipo_tramite         char(1),          --AGI 15JUL19 TEC
   @w_sec_seguro           int,              --AGI 19JUL19 TEC
   @w_secuencia_seguro     varchar(100),     --AGI 19JUL19 TEC
   @w_contador             smallint,         --AGI 19JUL19 TEC
   @w_cant_seguro          smallint,         --AGI 19JUL19 TEC
   @w_sec_incentivo        int,              --AGI 30JUL19 TEC
   @w_secuencia_incent     varchar(100),     --AGI 30JUL19 TEC
   @w_cant_incent          smallint,         --AGI 30JUL19 TEC
   @w_lsrv                 varchar(30),      --LRE 01AGO19 TEC
   @s_lsrv                 varchar(30)       --LRE 01AGO19 TEC

select @w_es_interciclo = 'N'

-- NEMONICO DE LA FORMA DE PAGO
select @w_op_forma_pago = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'NCRAHO'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR
end

select @w_lsrv = pa_char from cobis..cl_parametro
where pa_nemonico = 'SCVL'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR
end
 

if @s_lsrv is null
   select @s_lsrv = @w_lsrv

select @w_commit = 'N',
       @w_sesn = 0

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

--HACER CURSOR POR TODOS LOS DESEMBOLSOS CON FECHA MENOR O IGUAL A LA FECHA DE PROCESO.
-- CURSOR DE 
                                                                                                                                                                                                                                                 
declare cursor_operaciones cursor
for 
select op_operacion, op_banco, op_fecha_ini, op_cliente, op_grupo, op_tramite, op_cuenta, op_oficina, op_moneda, op_admin_individual,
       op_ref_grupal
from cob_cartera..ca_operacion x
where ((op_grupal = 'S' and op_ref_grupal is NULL) or EXISTS(select 1 from cob_cartera..ca_det_ciclo where dc_operacion = x.op_operacion
                                 and dc_tciclo = 'I'))
and   op_estado_hijas = 'P'
and   op_fecha_ini <= @w_fecha_proceso
and   op_operacion not in (select dm_operacion from cob_cartera..ca_desembolso
                           where dm_operacion = x.op_operacion
                            and  dm_estado    = 'A')
and   op_estado = 0

for read only
open  cursor_operaciones
fetch cursor_operaciones into  @w_operacion, @w_banco, @w_fecha_ini, @w_cliente, @w_grupo, @w_tramite, @w_cta_grupal, @w_oficina, @w_moneda, @w_admin_individual,
                               @w_ref_grupal
                                                                                                                                                                                                                                                              
while @@fetch_status = 0
begin

-- KDR 16Abr21: Se comenta seteo obligatorio de admin_individual N 
--select @w_admin_individual = 'N'   --LRE 28Ago19 Setear siempre Administracion Grupal


--LRE 23/Jul/19
--Para Operaciones de Interciclo
if exists (select 1 from cob_cartera..ca_det_ciclo
           where dc_operacion = @w_operacion
            and  dc_cliente    = @w_cliente
            and  dc_tciclo     = 'I') 
  select @w_es_interciclo  = 'S'


exec @w_ssn = ADMIN...rp_ssn

select @s_ssn  = @w_ssn,
       @s_user = 'USER_P_ASIN',
       @s_date = @w_fecha_proceso,
       @s_term = 'TERM1',
       @s_ofi  = @w_oficina,                   
       @s_srv  = 'CENTRAL'
  
   if (@@fetch_status = -1)
     return 710004
	 
-- KDR 16Abr21: Se comenta Validación de monto mínimo de ahorros    
/*--VALIDAR EL MONTO MINIMO DE AHORRO
exec @w_return             = cob_ahorros..sp_ah_val_saldocta_grp 
     @s_ssn                = @s_ssn, 
     @s_srv                = @s_srv, 
     @s_user               = @s_user,
     @s_term               = @s_term, 
     @s_date               = @w_fecha_proceso, 
     @s_ofi                = @s_ofi ,
     @i_cta_banco          = @w_cta_grupal,   
     @o_cumple_ahorro_base = @w_cumple_ahorro  out 
 
if @w_return <> 0 
begin
    select @w_error = @w_return
    select @w_sp_name = 'cob_ahorros..sp_ah_val_saldocta_grp'
    print 'ERROR AL VALIDAR EL MONTO MINIMO ' + cast (@w_cta_grupal as varchar)
    goto ERROR  
end */

-- KDR 16Abr21: Seteo de variable a S por no tomar en cuenta validación de monto mínimo de ahorro
SELECT @w_cumple_ahorro = 'S'

if (@w_cumple_ahorro = 'S' or @w_es_interciclo  = 'S' )--Se procede unicamente si el saldo a girar de la cuenta grupal es mayor que el monto minimo de ahorro
begin

    BEGIN TRAN

    select @w_commit = 'S'

    -----------------------------------   
    --EJECUCION DEL DESEMBOLSO GRUPAL
    -----------------------------------

    if @w_admin_individual = 'S' 
    begin
           update cob_credito..cr_tramite_grupal set tg_cuenta = @w_cta_grupal
           where tg_tramite = @w_tramite
           and   tg_monto   > 0

           if @@rowcount = 0
           begin
	       select @w_error = 725046
               print 'ERROR AL ACTUALIZAR CUENTA DE AHORRO EN HIJAS'
               goto ERROR 
           end

    end
    
    --INI AGI 15JUL19 TEC Desembolso de Renovacion
    select @w_tipo_tramite = tr_tipo
    from cob_credito..cr_tramite
    where tr_tramite = @w_tramite
    
    if @w_tipo_tramite = 'R' --Renovacion
    begin
    
        select @w_sp_name = 'sp_renovacion_grupal'
       
        exec @w_return = sp_renovacion_grupal 
             @s_srv     = @s_srv,    
             @s_ssn     = @s_ssn, 
             @s_user    = @s_user,     
             @s_term    = @s_term,     
             @s_date    = @s_date,     
             @s_ofi     = @s_ofi,
             @i_banco   = @w_banco
    end
    --FIN AGI
    else
    begin
        --ENVIAR A APLICAR EL DESEMBOLSO GRUPAL
        select @w_sp_name = 'sp_desembolso_grupal'
        
        exec @w_return = sp_desembolso_grupal
             @s_srv              = @s_srv,    
             @s_ssn              = @s_ssn, 
             @s_user             = @s_user,     
             @s_term             = @s_term,     
             @s_date             = @s_date,     
             @s_ofi              = @s_ofi,
             @i_tramite_grupal   = @w_tramite,
             @i_forma_desembolso = @w_op_forma_pago,
             @i_externo          = 'N'
    end
    
    if @w_return <> 0 
    begin
       select @w_error = @w_return       
       print 'ERROR AL REALIZAR EL DESEMBOLSO ' + cast (@w_return as varchar)
       goto ERROR 
    end
    else
    begin
      if @w_admin_individual = 'N' 
      begin
        	--RECUPERO EL SECUENCIAL DE LA TRANSACCION DE DESEMBOLSO 

        	select @w_secuencial  = min(dm_secuencial)
        	from   ca_desembolso
        	where  dm_operacion  =  @w_operacion
         	and    dm_estado     = 'A'

                                                                                                                                                                                                                                   
        	if @w_secuencial <= 0 or @w_secuencial is null begin
            		select @w_error = 701121
            		goto ERROR
        	end
      end
      else
      begin
      	--RECUPERO EL SECUENCIAL DE LA TRANSACCION DE DESEMBOLSO DE UNA DE LAS OPERACIONES HIJAS

      	select @w_secuencial  = min(dm_secuencial)
      	from   ca_desembolso
      	where  dm_operacion  = (select min(op_operacion) from cob_cartera..ca_operacion where op_ref_grupal = @w_banco)
       	and    dm_estado     = 'A'

                                                                                                                                                                                                                                 
      	if @w_secuencial <= 0 or @w_secuencial is null begin
          		select @w_error = 701121
          		goto ERROR
      	end
      end

	--ACTUALIZAR EL ESTADO DE LA OPERACION GRUPAL A D(Desembolsado)
	update cob_cartera..ca_operacion set op_estado_hijas = 'D'
	where op_operacion = @w_operacion

  	if @@error <> 0
	begin
 		select @w_error = 725030
 		print 'ERROR AL ACTUALIZAR LA OPERACION PADRE ' + cast (@w_banco as varchar)
	       	goto ERROR 
	end

	--ENVIAR A APLICAR LAS NOTAS DE DEBITO POR LOS SEGUROS

      if @w_es_interciclo = 'S'   --Para operaciones interciclo obtengo la op. del padre
       begin
          select @w_op_grupal = op_operacion
          from cob_cartera..ca_operacion
          where op_banco =  @w_ref_grupal
       end
       else
          select @w_op_grupal = @w_operacion
          
        execute @w_return = sp_debito_seguros
        @s_ssn            = @s_ssn,
        @s_sesn           = @s_ssn,
        @s_user           = 'USER_P_ASIN',
        @s_date           = @w_fecha_proceso,
        @s_ofi            = @w_oficina,
        @i_operacion      = @w_op_grupal,
        @i_cta_grupal     = @w_cta_grupal,
        @i_moneda         = @w_moneda,
        @i_fecha_proceso  = @w_fecha_proceso, 
        @i_oficina        = @w_oficina,
        @i_secuencial_trn = @w_secuencial,
        @i_es_interciclo  = @w_es_interciclo,
        @i_op_interciclo  = @w_operacion


        if @w_return <> 0
        begin
   		print 'ERROR AL EJECUTAR DEBITOS SEGUROS ' + cast (@w_banco as varchar)
            select @w_error = @w_return
            select @w_sp_name = 'cob_cartera..sp_debito_seguros'
            goto ERROR

        end  

        --INI AGI 25JUL19 APLICACION NOTA DEBITO/CREDITO POR INCENTIVOS
        
        exec @w_error =  sp_incentivos_grp
             @s_ssn               = @s_ssn,
             @s_sesn              = @s_ssn,
             @s_srv               = @s_srv,
             @s_user              = @s_user,            
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_opcion            = 'A',
             @i_operacion         = @w_operacion, 
             @i_secuencial_trn    = @w_secuencial,
             @o_mensaje           = @w_mensaje out
             
        if @w_error != 0 
        begin
            print 'ERROR INSERTANDO INCENTIVO DE CREDITO' + cast (@w_error as varchar)
            select @w_mensaje = 'Error insertando Incentivo de Credito:  '  + cast(@w_error as varchar)
            select @w_error = 725061
            goto ERROR  
        end
        --FIN AGI
        
        --Para Operaciones de Interciclo
        if @w_es_interciclo = 'S'
        begin
          if exists (select 1 from cob_cartera..ca_seguros_op 
		             where so_operacion  = @w_operacion
                     and  (so_estado      is  null or  so_estado <> 'A'))
		  begin 

            update cob_cartera..ca_seguros_op set so_secuencial_trn = @w_secuencial, so_estado = 'A'   --
            where so_operacion  = @w_operacion
             and  (so_estado      is  null or  so_estado <> 'A')


            if @@rowcount = 0
            begin
                select @w_error = 725044
                goto ERROR
            end
         end 

        end
        else
        begin
		   if exists (select 1 from cob_cartera..ca_seguros_op
		              where so_oper_padre  = @w_operacion
                      and  (so_estado      is  null or  so_estado <> 'A'))
		   begin 
              update cob_cartera..ca_seguros_op set so_secuencial_trn = @w_secuencial, so_estado = 'A'   --
              where so_oper_padre  = @w_operacion
              and  (so_estado      is  null or  so_estado <> 'A')

              if @@rowcount = 0
              begin
                select @w_error = 725044
                goto ERROR
              end
		   end 
        end     

	--ACTIVAR ORDENES DE PAGO 
	exec @w_return =  cob_cartera..sp_orden_pago
   	@s_ssn              = @s_ssn,
	@s_lsrv             = @s_lsrv,   --LRE 01AGO19
   	@s_user             = 'USER_P_ASIN', 
   	@s_date             = @w_fecha_proceso,
   	@i_operacion        = @w_operacion,
    @i_grupo            = @w_grupo

        if @w_return <> 0
        begin
   		print 'ERROR AL EJECUTAR ORDEN DE PAGO ' + cast (@w_banco as varchar)

            select @w_error = @w_return
            select @w_sp_name = 'cob_cartera..sp_orden_pago'
            goto ERROR

        end              
       
        --AGI ELIMINAR TABLAS DE INTEFACES       
        delete ca_interf_op_tmp         where iot_operacion  = @w_operacion
        delete ca_interf_hijas_tmp      where iht_operacion  = @w_operacion
        delete ca_interf_seguros_tmp    where ist_operacion  = @w_operacion
        delete ca_interf_benef_tmp      where ibt_operacion  = @w_operacion
        delete ca_interf_ordenp_tmp     where iot_operacion  = @w_operacion
        delete ca_interf_incentivo_tmp  where iic_operacion  = @w_operacion

     end
 
COMMIT TRAN

end   --if @w_cumple_ahorro = 'S'
else
begin
      print 'NO CUMPLE CON MINIMO DE AHORRO : ' + @w_cumple_ahorro + 'Cuenta: ' + @w_cta_grupal 
    select @w_error = 725048
    select @w_sp_name = 'sp_ah_val_saldocta_grp'
    goto ERROR

end

SIG:
fetch cursor_operaciones into  @w_operacion, @w_banco, @w_fecha_ini, @w_cliente, @w_grupo, @w_tramite, @w_cta_grupal, @w_oficina, @w_moneda, @w_admin_individual,
                               @w_ref_grupal

end -- WHILE CURSOR PRINCIPAL
                                                                                                                                                                                                                                 
close cursor_operaciones
deallocate cursor_operaciones

return 0

ERROR:
    
   select @w_msj_er = 'ERROR EN DESEMBOLSO OPERACION: ' + @w_banco

   if @w_commit = 'S'
   begin
        while @@trancount > 0 ROLLBACK TRAN


        exec cob_cartera..sp_errorlog
        @i_fecha = @s_date,
        @i_error = @w_error, 
        @i_usuario=@s_user, 
        @i_tran=7999,
        @i_tran_name=@w_sp_name,
        @i_cuenta= @w_banco,
        @i_rollback = 'S',
        @i_descripcion = @w_msj_er
 
      goto SIG
   end
   else      
   begin 
        exec cob_cartera..sp_errorlog
        @i_fecha = @s_date,
        @i_error = @w_error, 
        @i_usuario=@s_user, 
        @i_tran=7999,
        @i_tran_name=@w_sp_name,
        @i_cuenta= @w_banco,
        @i_rollback = 'N',
        @i_descripcion = @w_msj_er

      goto SIG
  

   end    

