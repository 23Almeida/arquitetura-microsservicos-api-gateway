# Manual do Projeto: Arquitetura de Microsserviços com API Gateway

## 1. Contexto do Projeto
Este projeto tem como objetivo demonstrar na prática os conceitos de redes, roteamento e alta disponibilidade através de uma arquitetura de microsserviços. A infraestrutura foi projetada para simular um ambiente corporativo real, focando na separação de responsabilidades e segurança.

**A arquitetura é composta por:**
* **API Gateway (Nginx):** Atua como o único ponto de entrada da rede (porta 8080). Ele roteia o tráfego, serve a interface visual (Front-end) e atua como um escudo contra ataques (Rate Limiting de 2 requisições/segundo).
* **Serviço de Usuários (Python/Flask):** API isolada na rede virtual responsável pelos dados de usuários.
* **Cluster de Produtos (Python/Flask):** Duas réplicas da API de produtos trabalhando em conjunto sob um **Balanceador de Carga (Load Balancer)** automático gerido pelo Docker.
* **Monitoramento (Zabbix):** Servidor rodando em paralelo para monitorar o tempo de atividade (Uptime) da infraestrutura.

## 2. Pré-requisitos
Para garantir a execução correta da infraestrutura, a máquina hospedeira precisa ter os seguintes softwares instalados:
* **Docker Desktop** (com o motor em execução / *Engine running*)
* **Docker Compose** (geralmente já incluso no Docker Desktop)
* Portas `8080` e `8081` livres no sistema operacional.

## 3. Instalação e Configuração
A vantagem desta arquitetura (Infraestrutura como Código) é que não há necessidade de instalações ou configurações manuais de bibliotecas.
1. Extraia o arquivo `.zip` deste projeto em uma pasta de sua preferência.
2. Certifique-se de que a estrutura de pastas contém o arquivo `docker-compose.yml` na raiz, acompanhado das pastas `nginx`, `servico-produtos`, `servico-usuarios` e `frontend`.
3. Abra um terminal de comando na raiz da pasta extraída.

## 4. Execução e Testes
Para inicializar toda a infraestrutura de rede, execute o comando abaixo no terminal:

```bash
docker-compose up --build