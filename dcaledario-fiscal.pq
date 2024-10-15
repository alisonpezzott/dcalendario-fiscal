let
    #"*****Parâmetros*****" = "",

    // Especifique a data inicial
    dataInicial = #date(2024, 4, 1), 
    
    // Quantidade da anos totais
    qtdAnos = 4, 

    // Utilize 1 segunda ~ 7 domingo,
    inicioSemana = 1, 

    #"*****Não alterar abaixo*****" = "",
    idioma = "pt-BR",
    diaInicial = Date.Day(dataInicial),
    anoInicial = Date.Year(dataInicial),
    duracao = Duration.Days(Date.AddYears(dataInicial, qtdAnos) - dataInicial),
    indice = {1..duracao},
    data = List.Dates(dataInicial, duracao, #duration(1, 0, 0, 0)),
    tbMesIndice =  Table.FromColumns({indice, data}, {"Indice", "Data"}),
    
    mesIndice = Table.AddColumn(
        tbMesIndice, 
        "MesIndice", 
        each List.Accumulate(
            List.Buffer(List.FirstN( tbMesIndice[Data], [Indice] )),
            0,
            (acumulado, atual) => if Date.Day(atual) = diaInicial 
                then acumulado + 1 
                else acumulado
        ), 
        Int64.Type
    )[MesIndice], 


    mesFiscalNum = List.Transform(mesIndice, (i) => if i <= 12 then i else Number.Mod(i - 1, 12) + 1),
    mesFiscalNome = List.Transform(mesFiscalNum, (i)=> Text.Proper(Date.MonthName(#date(anoInicial, i, 1), idioma))),
    mesFiscalNomeAbrev = List.Transform(mesFiscalNome, (i)=> Text.Start(i, 3)), 

    anoFiscalInicio = List.Transform(mesIndice, (i) => anoInicial - 1 + (if i <= 12 then 1 else Number.IntegerDivide(i-1, 12) + 1)),
    anoFiscalFim = List.Transform(anoFiscalInicio, (i) => i + 1),
    anoFiscal = List.Transform(List.Zip({anoFiscalInicio, anoFiscalFim}), (i) => Number.ToText(i{0}) & "/" & Number.ToText(i{1})),
    
    mesAnoFiscalNome = List.Transform(List.Zip({ mesFiscalNomeAbrev, anoFiscal }), (i) => i{0} & "-" & i{1}),
    mesAnoFiscalNum = List.Transform(List.Zip({ anoFiscalFim, mesFiscalNum }), (i) => i{0} * 100 + i{1}),
    mesAnoFiscalNumTexto = List.Transform( List.Zip({ mesFiscalNum, anoFiscal }), (i) => Number.ToText(i{0}) & "-" & i{1}),
    
    trimestreFiscalNum = List.Transform(mesFiscalNum, (i) => Number.IntegerDivide(i - 1, 3) + 1),
    trimestreFiscalNome = List.Transform(trimestreFiscalNum, (i)=> "T" & Number.ToText(i)),
    trimestreAnoFiscalNome = List.Transform(List.Zip({trimestreFiscalNome, anoFiscal}), (i)=> Text.Combine({i{0}, "-", i{1}})),
    trimestreAnoFiscalNum = List.Transform(List.Zip({anoFiscalFim, trimestreFiscalNum}), (i)=> i{0} * 100 + i{1}),

    semestreFiscalNum = List.Transform(List.Buffer(mesFiscalNum), (i) => if i <= 6 then 1 else 2),
    semestreFiscalNome = List.Transform(semestreFiscalNum, (i) => "S" & Number.ToText(i)),
    semestreAnoFiscalNome = List.Transform(List.Zip({semestreFiscalNome, anoFiscal}), (i)=> Text.Combine({i{0}, "-", i{1}})),
    semestreAnoFiscalNum = List.Transform(List.Zip({anoFiscalFim, semestreFiscalNum}), (i)=> i{0} * 100 + i{1}), 

    bimestreFiscalNum = List.Transform(mesFiscalNum, (i) => Number.IntegerDivide(i - 1, 2) + 1),
    bimestreFiscalNome = List.Transform(bimestreFiscalNum, (i)=> "B" & Number.ToText(i)),
    bimestreAnoFiscalNome = List.Transform(List.Zip({bimestreFiscalNome, anoFiscal}), (i)=> Text.Combine({i{0}, "-", i{1}})),
    bimestreAnoFiscalNum = List.Transform(List.Zip({anoFiscalFim, bimestreFiscalNum}), (i)=> i{0} * 100 + i{1}), 
    
    diaDaSemanaNum = List.Transform(data, (i) => Date.DayOfWeek(i, inicioSemana) + 1),
    diaDaSemanaNome = List.Transform(data, (i) => Text.Proper(Date.DayOfWeekName(i, idioma))),
    diaDaSemanaNomeAbrev = List.Transform( diaDaSemanaNome, (i) =>  Text.Start(i, 3)), 
    
    // Cria uma tabela a partir das listas dos anos e dias da semana e adiciona um índice
    preSemanasAno = Table.FromColumns(
        { anoFiscal, diaDaSemanaNum, indice }, 
        {"Ano", "DiaDaSemana", "Indice"}
    ),

    // Adiciona a coluna semana do ano, fazendo o acumulado a cada início da semana
    adicionaSemanaAno = let tbPre = Table.Buffer(preSemanasAno) in
        Table.AddColumn(
        tbPre, 
        "SemanaDoAnoN", 
        (f)=> Table.RowCount(
            Table.SelectRows(
                tbPre, 
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
            each if List.Min([SemanaDoAnoN]) = 0 then 1 else 0, 
            Int64.Type
        }}
    ), 

    // Ajusta as semanas do ano com o delta e joga para lista
    semanaDoAnoFiscalNum = Table.AddColumn(
        Table.Join(adicionaSemanaAno, {"Ano"}, deltaAjuste, {"Ano"}), 
        "SemanaDoAnoNum", 
        each [SemanaDoAnoN] + [Delta]
    )[SemanaDoAnoNum],

    semanaDoAnoFiscalNome = List.Transform(semanaDoAnoFiscalNum, (i) => "S" & Text.PadStart(Number.ToText(i), 2, "0")),
    semanaAnoFiscalNome = List.Transform(List.Zip({semanaDoAnoFiscalNome, anoFiscal}), (i) => i{0} & "-" & i{1}),
    semanaAnoFiscalNum = List.Transform(List.Zip({anoFiscalFim, semanaDoAnoFiscalNum}), (i) => i{0} * 100 + i{1}),
    
    listasParaColunas = Table.Buffer(  Table.FromColumns(
        {
            data,
            diaDaSemanaNome,
            diaDaSemanaNomeAbrev,
            diaDaSemanaNum,
            anoFiscal,
            anoFiscalInicio,
            anoFiscalFim,
            mesFiscalNome,
            mesFiscalNomeAbrev,
            mesFiscalNum,
            mesAnoFiscalNome,
            mesAnoFiscalNum,
            mesAnoFiscalNumTexto,
            semanaDoAnoFiscalNome,
            semanaDoAnoFiscalNum,
            semanaAnoFiscalNome,
            semanaAnoFiscalNum,
            trimestreFiscalNome,
            trimestreFiscalNum,
            trimestreAnoFiscalNome,
            trimestreAnoFiscalNum,
            semestreFiscalNome,
            semestreFiscalNum,
            semestreAnoFiscalNome,
            semestreAnoFiscalNum,
            bimestreFiscalNome,
            bimestreFiscalNum,
            bimestreAnoFiscalNome,
            bimestreAnoFiscalNum
        }, 
        {
            "Data",
            "DiaDaSemanaNome",
            "DiaDaSemanaNomeAbrev",
            "DiaDaSemanaNum",
            "AnoFiscal",
            "AnoFiscalInicio",
            "AnoFiscalFim",
            "MesFiscalNome",
            "MesFiscalNomeAbrev",
            "MesFiscalNum",
            "MesAnoFiscalNome",
            "MesAnoFiscalNum",
            "MesAnoFiscalNumTexto",
            "SemanaDoAnoFiscalNome",
            "SemanaDoAnoFiscalNum",
            "SemanaAnoFiscalNome",
            "SemanaAnoFiscalNum",
            "TrimestreFiscalNome",
            "TrimestreFiscalNum",
            "TrimestreAnoFiscalNome",
            "TrimestreAnoFiscalNum",
            "SemestreFiscalNome",
            "SemestreFiscalNum",
            "SemestreAnoFiscalNome",
            "SemestreAnoFiscalNum",
            "BimestreFiscalNome",
            "BimestreFiscalNum",
            "BimestreAnoFiscalNome",
            "BimestreAnoFiscalNum"
        }    
    )),

    tipoAlterado = Table.TransformColumnTypes(
        listasParaColunas,
        {
            {"Data", type date}, 
            {"DiaDaSemanaNome", type text}, 
            {"DiaDaSemanaNomeAbrev", type text}, 
            {"DiaDaSemanaNum", Int64.Type}, 
            {"AnoFiscal", type text}, 
            {"MesFiscalNome", type text}, 
            {"MesFiscalNomeAbrev", type text}, 
            {"MesAnoFiscalNome", type text}, 
            {"MesAnoFiscalNumTexto", type text}, 
            {"SemanaDoAnoFiscalNome", type text}, 
            {"SemanaAnoFiscalNome", type text}, 
            {"TrimestreAnoFiscalNome", type text}, 
            {"TrimestreFiscalNome", type text}, 
            {"SemestreFiscalNome", type text}, 
            {"SemestreAnoFiscalNome", type text}, 
            {"BimestreFiscalNome", type text}, 
            {"BimestreAnoFiscalNome", type text}, 
            {"BimestreAnoFiscalNum", Int64.Type}, 
            {"BimestreFiscalNum", Int64.Type}, 
            {"SemestreAnoFiscalNum", Int64.Type}, 
            {"SemestreFiscalNum", Int64.Type}, 
            {"TrimestreAnoFiscalNum", Int64.Type}, 
            {"TrimestreFiscalNum", Int64.Type}, 
            {"SemanaAnoFiscalNum", Int64.Type}, 
            {"SemanaDoAnoFiscalNum", Int64.Type}, 
            {"MesAnoFiscalNum", Int64.Type}, 
            {"MesFiscalNum", Int64.Type}, 
            {"AnoFiscalFim", Int64.Type}, 
            {"AnoFiscalInicio", Int64.Type}
        }
    )

in
    tipoAlterado
