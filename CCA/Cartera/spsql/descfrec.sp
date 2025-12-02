/******************************************************************/
/*  Archivo:            descfrec.sp                               */
/*  Stored procedure:   sp_desc_frecuencia                        */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 16-Jul-2019                               */
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
/*   - Genera descripci¢n de la frecuencia de pago en singular    */
/*     /plural                                                    */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_desc_frecuencia') IS NOT NULL
	DROP PROCEDURE dbo.sp_desc_frecuencia
GO

create proc sp_desc_frecuencia
   @i_tipo             char(1),  --(S)INGULAR  / (P)LURAL
   @i_tdividendo       catalogo,
   @o_frecuencia       varchar(30) out
 
as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(255),
   @w_frecuencia           varchar(20)


-----------------------------------------------------------
--Operacion para devolver datos de la cabecera del reporte
-----------------------------------------------------------

if @i_tipo = 'S'    --Singular
begin

      SELECT @w_frecuencia =   (select case 
                when td_tdividendo = 'D' then 'DIA'
                when td_tdividendo = 'A' then 'ANIO'
                when td_tdividendo = 'M' then 'MES'
                when td_tdividendo = 'T' then 'TRIMESTRE'
                when td_tdividendo = 'S' then 'SEMESTRE'
                when td_tdividendo = 'B' then 'BIMESTRE'
                when td_tdividendo = 'W' then 'SEMANA'
                when td_tdividendo = 'Q' then 'QUINCENA'
        		end)
       from cob_cartera..ca_tdividendo
       where td_tdividendo = @i_tdividendo 

       if @@rowcount = 0
       begin
             select @w_error = 725003
             goto ERROR
       end

       select @w_frecuencia = isnull(@w_frecuencia, ' ')

       select @o_frecuencia = @w_frecuencia

end
else
if @i_tipo = 'P'    --Plural
begin

      SELECT @w_frecuencia =   (select case 
                when td_tdividendo = 'D' then 'DIAS'
                when td_tdividendo = 'A' then 'ANIOS'
                when td_tdividendo = 'M' then 'MESES'
                when td_tdividendo = 'T' then 'TRIMESTRES'
                when td_tdividendo = 'S' then 'SEMESTRES'
                when td_tdividendo = 'B' then 'BIMESTRES'
                when td_tdividendo = 'W' then 'SEMANAS'
                when td_tdividendo = 'Q' then 'QUINCENAS'
        		end)
       from cob_cartera..ca_tdividendo
       where td_tdividendo = @i_tdividendo 

       if @@rowcount = 0
       begin
             select @w_error = 725003
             goto ERROR
       end


       select @w_frecuencia = isnull(@w_frecuencia, ' ')

       select @o_frecuencia = @w_frecuencia

end









return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = @w_mensaje,
    @i_sev    = 0
   
     return @w_error
  

GO

