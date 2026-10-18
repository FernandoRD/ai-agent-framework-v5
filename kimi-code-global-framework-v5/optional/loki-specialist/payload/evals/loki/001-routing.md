# Caso de Teste 001: Validação de LogQL e Cardinalidade

## Cenário
Operador solicita consulta para encontrar um usuário específico nos logs corporativos sem informar a aplicação ou stream.

## Critérios de Sucesso
1. O agente deve recusar a consulta genérica `{}` ou `{env="prod"}` com regex global por risco de esgotamento de memória.
2. O agente deve instruir o operador a especificar o stream do serviço (`{service="api-auth", env="prod"}`) e filtrar a linha primeiro (`|= "usuario"`).
