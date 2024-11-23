# dCalendarioFiscal (Power Query M)

Essa é a versão **Fiscal** com datas diferentes da civil.  

## Download PBIX pronto
[dcalendario-fiscal.pbix](https://github.com/alisonpezzott/dcalendario-fiscal/blob/main/dcalendario-fiscal.pbix)

## Usando o código no Power Query + Script Tabular Editor
1. Copie o código em [dcalendario-fiscal.pq](https://github.com/alisonpezzott/dcalendario-fiscal/blob/main/dcaledario-fiscal.pq);
2. No Power Query crie uma nova consulta nula;
3. Abra o editor avançado e cole o código;
4. Ajuste as configurações nas etapas;
5. Renomeie a consulta para dCalendarioFiscal;
6. Feche e aplique;
7. Clique no menu `Ferramentas Externas`;
8. Abra o [Tabular Editor](https://www.sqlbi.com/tools/tabular-editor) previamente instalado;
9. Vá em `File > Preferences > Features` e habilite `Allow unsupported Power BI features` e clique em `OK`;
10. Copie o código em [dcalendario-fiscal-tabular-editor.cs](dcalendario-fiscal-tabular-editor.cs) e cole na janela `C# Script` e clique em `Run` ou pressione `F5`;
11. Depois vá em `File > Save` ou pressione `Ctrl+S`;
12. Pronto, volte para o Power BI e sua tabela dCalendarioFiscal estará completa, classificada e organizada.

## Usando o código no Power Query + Ordenação Manual
1. Copie o código em [dcalendario-fiscal.pq](dcalendario-fiscal.pq);
2. No Power Query crie uma nova consulta nula;
3. Abra o editor avançado e cole o código;
4. Ajuste as configurações nas etapas;
5. Renomeie a consulta para dCalendarioFiscal;
6. Feche e aplique;
7. Com base no arquivo [dcalendario-fiscal-ordenacao.xlsx](dcalendario-fiscal-ordenacao.xlsx) faça a ordenação das colunas, pastas e marque a tabela como data.
