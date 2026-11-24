# Prova - Data Warehouse na Nuvem com AWS

## Integrantes
- Alisson Ibiapino da Silva - RA 2041382521023
- Daniel da Silva Pereira - RA 2041382321029
- Elves Juliano Aparecido da Silva - RA 2041382521008

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

### Enunciado 6
O S3 usa um Gateway Endpoint, ele adiciona uma rota na tabela de rotas da VPC para enviar o tráfego internamente pela rede da AWS sem passar pela internet.

O STS e o AWS Secrets Manager não suportam endpoints de gateway e exigem Interface Endpoints, a AWS cria placas de rede com IPs privados dentro da sub-rede para que o job do Glue consiga alcançar esses serviços externos de forma privada.

Se o DNS privado desligar, os endereços públicos desses serviços resolverão para seus IPs públicos em vez dos IPs privados das ENIs, fazendo o job falhar por timeout por não ter rota de saída para a internet.

### Enunciado 7
- **row id = bigint:** Todos os valores da coluna são números inteiros sem caracteres especiais, o crawler entendeu o tipo inteiro padrão de 64 bits.
- **postal code = bigint:** Mesma coisa do row id, o código postal do CSV só tem números, o crawler entendeu o tipo inteiro padrão de 64 bits.
- **sales = double:** Os valores de venda são números decimais com ponto separador, então o crawler entendeu que tinha que colocar um tipo de ponto flutuante, como o double.

### Enunciado 11
O fim do calendario usa a data de envio porque o envio só acontece depois do pedido.