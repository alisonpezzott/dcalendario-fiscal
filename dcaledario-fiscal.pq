let
    dataInicial = #date(2024, 4, 1),
    qtdAnos = 3,
    // 0 Domingo, 1 Segunda .. 6 Sábado
    inicioDaSemana =  1,
    dataFinal = Date.AddDays(Date.AddYears(dataInicial, qtdAnos), - 1),
    diaDoInicioDoMes = Date.Day(dataInicial),
    anoInicialBase = Date.Year(dataInicial),
    idioma = "pt-BR",
    totalDias = Duration.Days(dataFinal - dataInicial) + 1,
    listaDatas = List.Dates(dataInicial, totalDias, #duration(1, 0, 0, 0)),
    tabelaDatas = Table.FromList(listaDatas, Splitter.SplitByNothing(), type table [Data = date]),
    adDataIndice = Table.AddIndexColumn(tabelaDatas, "DataIndice", 1, 1, Int64.Type),
    adMesIndice = Table.AddColumn(
        adDataIndice,
        "MesIndice",
        each List.Accumulate(
            List.FirstN(adDataIndice[Data], [DataIndice]),
            0,
            (acumulado, atual) => 
                if Date.Day(atual) = diaDoInicioDoMes 
                    then acumulado + 1 
                    else acumulado
        ),
        Int64.Type
    ),
    listaFonte = Table.ToRows(adMesIndice),
    fxTransformaLista = (Data, DataIndice, MesIndice) =>
        let
            
            diaSemanaNome = Text.Proper(Date.ToText(Data, [Format = "dddd", Culture = idioma])),
            mesNum = if MesIndice <= 12  then MesIndice else Number.Mod(MesIndice - 1, 12) + 1,
            mesNome = Text.Proper(Date.ToText(#date(anoInicialBase, mesNum, 1), [Format = "MMMM", Culture = idioma])),
            mesNomeAbrev = Text.Start(mesNome, 3),
            anoInicial = anoInicialBase - 1 + (if MesIndice <= 12 then 1 else Number.IntegerDivide(MesIndice - 1, 12) + 1),
            anoFinal = anoInicial + 1,
            ano = Number.ToText(anoInicial) & "/" & Number.ToText(anoFinal),
            trimestreNum = Number.IntegerDivide(mesNum - 1, 3) + 1,
            trimestreNome = "T" & Number.ToText(trimestreNum),
            semestreNum = if mesNum <= 6 then 1 else 2,
            semestreNome = "S" & Number.ToText(semestreNum),
            bimestreNum = Number.IntegerDivide(mesNum - 1, 2) + 1,
            bimestreNome = "B" & Number.ToText(bimestreNum)
        in
            {
                DataIndice,
                Data,
                diaSemanaNome,
                Text.Start(diaSemanaNome, 3),
                Date.DayOfWeek(Data, inicioDaSemana) + 1,
                mesNum,
                mesNome,
                mesNomeAbrev,
                anoInicial * 100 + mesNum,
                mesNomeAbrev & "-" & ano,
                Text.PadStart(Number.ToText(mesNum), 2, "0") & "-" & ano,
                anoInicial,
                anoFinal,
                ano,
                trimestreNum,
                trimestreNome,
                anoInicial * 100 + trimestreNum,
                trimestreNome & "-" & ano,
                semestreNum,
                semestreNome,
                anoInicial * 100 + semestreNum,
                semestreNome & "-" & ano,
                bimestreNum,
                bimestreNome,
                anoInicial * 100 + bimestreNum,
                bimestreNome & "-" & ano
            },
    tabelaSaida = #table(
        type table [
            DataFiscalIndice = Int64.Type,
            DataFiscal = date,
            DiaSemanaFiscalNome = text,
            DiaSemanaFiscalNomeAbrev = text,
            DiaSemanaFiscalNum = Int64.Type,
            MesFiscalNum = Int64.Type,
            MesFiscalNome = text,
            MesFiscalNomeAbrev = text,
            MesAnoFiscalNum = Int64.Type,
            MesAnoFiscalNome = text,
            MesAnoFiscalNumTexto = text,
            AnoFiscalInicial = Int64.Type,
            AnoFiscalFinal = Int64.Type,
            AnoFiscal = text,
            TrimestreFiscalNum = Int64.Type,
            TrimestreFiscalNome = text,
            TrimestreAnoFiscalNum = Int64.Type,
            TrimestreAnoFiscalNome = text,
            SemestreFiscalNum = Int64.Type,
            SemestreFiscalNome = text,
            SemestreAnoFiscalNum = Int64.Type,
            SemestreAnoFiscalNome = text,
            BimestreFiscalNum = Int64.Type,
            BimestreFiscalNome = text,
            BimestreAnoFiscalNum = Int64.Type,
            BimestreAnoFiscalNome = text
        ],
        List.Transform(listaFonte, (i) => fxTransformaLista(i{0}, i{1}, i{2}))
    ),
    adSemanaDoAno =  
        let 
            tabelaBuffer = Table.Buffer( tabelaSaida[[AnoFiscalInicial], [DiaSemanaFiscalNum]] ),
            listaColunas = List.Buffer(Table.ToColumns(tabelaBuffer)),
            indices = List.Buffer({ 0 .. (Table.RowCount(tabelaBuffer) - 1)}),
            anos = List.Buffer(listaColunas{0}),
            diasDaSemana = List.Buffer(listaColunas{1})
        in 
            Table.AddColumn(
                tabelaSaida,
                "SemanaFiscalNum",
                each List.Accumulate(
                    List.FirstN(indices, [DataFiscalIndice]),
                    [Ano = 0, Semana = 1],
                    (acumulado, atual) => [
                        Ano = anos{atual},
                        Semana =  if anos{atual} <> acumulado[Ano] then 1 else 
                            if diasDaSemana{atual} = 1 then acumulado[Semana] + 1 else acumulado[Semana]
                    ] 
                )[Semana],
                Int64.Type
            ),
    adColunasFinais = Table.AddColumn(
        adSemanaDoAno,
        "ColunasFinais",
        each [
            SemanaAnoFiscalNum = [AnoFiscalInicial] * 100 + [SemanaFiscalNum],
            SemanaAnoFiscalNome = "S"
                & Text.PadStart(Text.From([SemanaFiscalNum]), 2, "0")
                & "-" & [AnoFiscal]
        ],
        type [SemanaAnoFiscalNum = Int64.Type, SemanaAnoFiscalNome = text]
    ),
    expColunasFinais = Table.ExpandRecordColumn(
        adColunasFinais,
        "ColunasFinais",
        Record.FieldNames(adColunasFinais[ColunasFinais]{0})
    )
in
    expColunasFinais
