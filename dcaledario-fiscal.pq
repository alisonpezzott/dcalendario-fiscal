let
    #"*****Parâmetros*****" = "",

    // Especifique a data inicial
    dataInicial = #date(2023, 7, 20), 
    
    // Quantidade da anos totais
    qtdAnos = 3, 

    // Utilize 1 segunda ~ 7 domingo,
    inicioSemana = 1, 

    #"*****Não alterar abaixo*****" = "",
    idioma = "pt-BR",

    diaInicial = Date.Day(dataInicial),
    anoInicial = Date.Year(dataInicial),   
    datas = List.Dates(
        dataInicial, 
        Duration.Days(Date.AddYears(dataInicial, qtdAnos) - dataInicial), 
        #duration(1, 0, 0, 0)
    ), 

    // Lista dos meses totais da base acumulados quando repete o dia inicial
    mesesIndice = List.Transform(
        List.Buffer(datas), 
        each List.Count(
            List.Select(
                List.Dates(
                    dataInicial, 
                    Duration.Days(_ - dataInicial) + 1, 
                    #duration(1, 0, 0, 0)
                ), 
                each Date.Day(_) = diaInicial
            )
        )
    ), 

    meses = List.Transform(
        List.Buffer(mesesIndice), 
        each if _ <= 12 then _ else Number.Mod(_ - 1, 12) + 1
    ), 

    anos = List.Transform(
        List.Buffer(mesesIndice), 
        each anoInicial + (if _ <= 12 then 1 else Number.IntegerDivide(_-1, 12) + 1)
    ),
    
    trimestres = List.Transform(List.Buffer(meses), each Number.IntegerDivide(_, 4) + 1), 

    semestres = List.Transform(List.Buffer(meses), each if _ <= 6 then 1 else 2), 

    bimestres = List.Transform(List.Buffer(meses), each Number.IntegerDivide(_ - 1, 2) + 1), 
    
    diasDaSemana = List.Transform(datas, each Date.DayOfWeek(_, inicioSemana) + 1), 
    
    // Cria uma tabela a partir das listas dos anos e dias da semana e adiciona um índice
    preSemanasAno = Table.AddIndexColumn(
        Table.FromColumns(
            { anos, diasDaSemana }, 
            {"Ano", "DiaDaSemana"}
        ), 
        "Indice", 
        1, 
        1,
        Int64.Type
    ), 

    // Adiciona a coluna semana do ano, fazendo o acumulado a cada início da semana
    adicionaSemanaAno = Table.AddColumn(
        preSemanasAno, 
        "SemanaDoAno", 
        (f)=> Table.RowCount(
            Table.SelectRows(
                preSemanasAno, 
                (d)=>
                d[Ano] = f[Ano] and
                d[Indice] <= f[Indice] and
                d[DiaDaSemana] = inicioSemana
            )
        ),
        Int64.Type
    ), 

    // Cria uma tabela com ajuste para somar 1 quando a primeira semana retorna 0 (zero)
    deltaAjuste = Table.Group(
        adicionaSemanaAno, 
        {"Ano"}, 
        {{
            "Delta", 
            each if List.Min([SemanaDoAno]) = 0 then 1 else 0, 
            Int64.Type
        }}
    ), 

    // Ajusta as semanas do ano com o delta e joga para lista
    semanasDoAno = Table.AddColumn(
        Table.Join(adicionaSemanaAno, {"Ano"}, deltaAjuste, {"Ano"}), 
        "SemanaDoAno_", 
        each [SemanaDoAno] + [Delta]
    )[SemanaDoAno_], 

    // Cria uma tabela a partir das listas indiduais
    listasParaColunas = Table.FromColumns(
        // Invocação das listas
        {
            datas, 
            meses, 
            anos, 
            trimestres, 
            semestres, 
            bimestres, 
            diasDaSemana, 
            semanasDoAno
        }, 

        // Nomes das colunas
        {
            "Data", 
            "MesFiscalNum", 
            "AnoFiscal", 
            "TrimestreFiscalNum", 
            "SemestreFiscalNum", 
            "BimestreFiscalNum", 
            "DiaDaSemanaNum", 
            "SemanaDoAnoFiscalNum"
        }
    ),

    tipagemPrimaria = Table.TransformColumnTypes(
        listasParaColunas,{
            {"Data", type date}, 
            {"MesFiscalNum", Int64.Type}, 
            {"AnoFiscal", Int64.Type}, 
            {"TrimestreFiscalNum", Int64.Type}, 
            {"SemestreFiscalNum", Int64.Type}, 
            {"BimestreFiscalNum", Int64.Type}, 
            {"DiaDaSemanaNum", Int64.Type}, 
            {"SemanaDoAnoFiscalNum", Int64.Type}
        }
    ),

    // Adicionando colunas personalizadas
    // 
    colunasPersonalizadasAdicionadas = Table.AddColumn(
        tipagemPrimaria, 
        "ColunasPersonalizadas", 
        each [
            DiaDaSemanaNome = Text.Proper(Date.DayOfWeekName([Data], idioma)),
            DiaDaSemanaNomeAbrev = Text.Start(Text.Proper(Date.DayOfWeekName([Data], idioma)), 3),
            MesFiscalNome = Text.Proper(Date.MonthName(#date([AnoFiscal], [MesFiscalNum], 1), idioma)),
            MesFiscalNomeAbrev = Text.Start(Text.Proper(Date.MonthName(#date([AnoFiscal], [MesFiscalNum], 1), idioma)), 3),
            MesAnoFiscalNome = Text.Proper(Date.ToText(#date([AnoFiscal], [MesFiscalNum], 1), [Format="MMM/yy", Culture=idioma])),
            MesAnoFiscalNum = [AnoFiscal] * 100 + [MesFiscalNum],
            TrimestreFiscalNome = "Tri " & Number.ToText([TrimestreFiscalNum]), 
            TrimestreAnoFiscalNome = "Tri " & Number.ToText([TrimestreFiscalNum]) & "/" & Text.End(Number.ToText([AnoFiscal]), 2),
            TrimestreAnoFiscalNum = [AnoFiscal] * 10 + [TrimestreFiscalNum],
            SemestreFiscalNome = "Sem " & Number.ToText([SemestreFiscalNum]),
            SemestreAnoFiscalNome = "Sem " & Number.ToText([SemestreFiscalNum]) & "/" & Text.End(Number.ToText([AnoFiscal]), 2),
            SemestreAnoFiscalNum = [AnoFiscal] * 10 + [SemestreFiscalNum],
            BimestreFiscalNome = "Bim " & Number.ToText([BimestreFiscalNum]),
            BimestreAnoFiscalNome = "Bim " & Number.ToText([BimestreFiscalNum]) & "/" & Text.End(Number.ToText([AnoFiscal]), 2),
            BimestreAnoFiscalNum = [AnoFiscal] * 10 + [BimestreFiscalNum],
            SemanaAnoFiscalNome = "Sem " & Text.PadStart(Number.ToText([SemanaDoAnoFiscalNum]), 2, "0") & "/" & Text.End(Number.ToText([AnoFiscal]), 2),
            SemanaAnoFiscalNum = [AnoFiscal] * 100 + [SemanaDoAnoFiscalNum]
        ],
        type [
            DiaDaSemanaNome = text,
            DiaDaSemanaNomeAbrev = text,
            MesFiscalNome = text,
            MesFiscalNomeAbrev = text,
            MesAnoFiscalNome = text,
            MesAnoFiscalNum = Int64.Type,
            TrimestreFiscalNome = text, 
            TrimestreAnoFiscalNome = text,
            TrimestreAnoFiscalNum = Int64.Type,
            SemestreFiscalNome = text,
            SemestreAnoFiscalNome = text,
            SemestreAnoFiscalNum = Int64.Type,
            BimestreFiscalNome = text,
            BimestreAnoFiscalNome = text,
            BimestreAnoFiscalNum = Int64.Type,
            SemanaAnoFiscalNome = text,
            SemanaAnoFiscalNum = Int64.Type
        ]
    ),
    colunasPersonalizadasExpandidas = Table.ExpandRecordColumn(
        colunasPersonalizadasAdicionadas, 
        "ColunasPersonalizadas",  
        Record.FieldNames(colunasPersonalizadasAdicionadas{0}[ColunasPersonalizadas])
    )
in
    colunasPersonalizadasExpandidas