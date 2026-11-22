# Prova - Data Warehouse na Nuvem com AWS

## Integrantes
- Alisson Ibiapino da Silva - RA 2041382521023

## Ambiente AWS
- Integrante dono da conta: Alisson Ibiapino da Silva
- RA usado nos nomes dos recursos: 2041382521023
- ID da conta AWS: 733947976329 (7339-4797-6329)
- Região: us-east-1

## Dataset

### Enunciado 02
- **(a) a quantidade de linhas de dados, sem o cabeçalho:** 9800
- **(b) o formato das duas colunas de data, justificando a ordem entre dia e mês com um valor do próprio arquivo que só admita uma leitura:** as duas colunas estão no formato dd/mm/yyyy (dia/mês/ano), pois não há números de meses maiores do que 12, e em diversas linhas, como o Row ID 13, tem o Order Date 15/04/2018
- **(c) quantas linhas não têm código postal:** 11 linhas
- **(d) um nome de produto que contenha vírgula, copiado exatamente como aparece no arquivo, e uma frase explicando por que essa vírgula não separa colunas:** "Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter", a vírgula não separa colunas pois está dentro de aspas duplas

## Respostas
### Enunciado 4
- **REGRA 1 Type:** Libera a porta do Postgre (5432) para as conexões que vem da internet. Sem essa regra, o comand psql travaria e não funcionaria.
- **REGRA 2 Source:** O firewall do Glue bloqueia tudo por padrão, mesmo se tiver no mesmo grupo que ele, essa regra permite que tem pertence ao grupo pode falar com ele, por causa disso o Source é o próprio grupo. Sem essa regra o JDBC vai dar timeout, pois seria barrado pelo Glue.
