
from flask import Flask, send_file, render_template_string
import os

app = Flask(__name__)

# Указываем путь к директории, откуда будут раздаваться файлы
DOWNLOAD_FOLDER = '/distr'

def join_paths(*paths):
    return '/'.join(paths)

@app.route('/distr/', methods=['GET'])
@app.route('/distr/<path:subpath>', methods=['GET'])
def list_files(subpath=''):
    # Используем функцию join_paths для соединения путей
    if subpath == '':
        full_path = DOWNLOAD_FOLDER
        subpath = '/distr'
    else:
        full_path = join_paths(DOWNLOAD_FOLDER, subpath)

    if not os.path.exists(full_path):
        return '404 Not Found', 404

    if os.path.isfile(full_path):
        return send_file(full_path)

    # Получаем список файлов и директорий
    files = os.listdir(full_path)
    files_list = []
    
    for file in files:
        # Используем функцию join_paths для формирования file_path
        file_path = join_paths(full_path, file)  # Используем обратные слэши
        if file_path.startswith('.'):
            file_path = file_path[1:]        
        files_list.append(f'<li><a href="{file_path}">{file}</a></li>')
    
    # Формируем HTML-страницу с индексом
    return render_template_string('''
        <!doctype html>
        <html>
            <head><title>Index of {{ path }}</title></head>
            <body>
                <h1>Index of {{ path }}</h1>
                <ul>
                    {{ files|safe }}
                </ul>
            </body>
        </html>
    ''', path=subpath, files=''.join(files_list))

if __name__ == '__main__':
    # Убедитесь, что папка для раздачи существует
    os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)
    app.run(host='0.0.0.0', port=5000)
