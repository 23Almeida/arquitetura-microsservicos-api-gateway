FROM python:3.9-slim

# Define a pasta de trabalho dentro do container
WORKDIR /app

# Copia os arquivos de dependência e instala
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copia o código da aplicação
COPY app.py .

# Comando para rodar a aplicação quando o container iniciar
CMD ["python", "app.py"]