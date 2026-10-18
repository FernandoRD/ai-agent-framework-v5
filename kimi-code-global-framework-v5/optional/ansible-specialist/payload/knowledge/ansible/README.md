# Base de Conhecimento: Ansible

Este diretório armazena diretrizes e convenções de automação com Ansible adotadas na organização.

## Diretrizes Institucionais

1. **Repositório de Roles**: Todas as roles corporativas devem conter documentação em `README.md` detalhando variáveis obrigatórias e exemplos de inclusão.
2. **Políticas de Tags**:
   - `install`: Somente instalação de pacotes e repositórios;
   - `config`: Atualização de templates e arquivos de configuração;
   - `service`: Reinicialização e gestão de serviços;
   - `check`: Auditoria e diagnóstico sem mutação.
3. **Segurança**:
   - Todos os arquivos com senhas devem conter o sufixo `_vault.yml` e estar criptografados no repositório.
