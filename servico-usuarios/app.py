import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/usuarios')
def get_usuarios():
    return jsonify({
        "status": "Sucesso",
        "servico": "API de Usuários",
        "maquina_que_respondeu": socket.gethostname(), # Retorna o ID do container
        "dados": ["Alice", "Bob", "Carlos", "Diana"]
    })

# Rota do sensor do Docker
@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)