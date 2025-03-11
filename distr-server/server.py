
from flask import Flask, send_file, render_template_string
import os
import tempfile

app = Flask(__name__)

# Указываем путь к директории, откуда будут раздаваться файлы
DOWNLOAD_FOLDER = '/distr'
FORBIDDEN_HTML_FILE = None  # Изначально переменная для файла равна None

def join_paths(*paths):
    return '/'.join(paths)

def create_forbidden_html():
    global FORBIDDEN_HTML_FILE  # Указываем, что будем использовать глобальную переменную
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.html')
    temp_file.write(b'<!doctype html><html><head><title>403 Forbidden</title></head>'
                    b'<body><h1>403 Forbidden</h1><p>HTML files are not allowed.</p></body></html>')
    temp_file.close()
    FORBIDDEN_HTML_FILE = temp_file.name  # Сохраняем имя файла в глобальной переменной

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
        # Проверяем, является ли файл HTML - они не нужны :-)
        if full_path.endswith('.htm') or full_path.endswith('.html'):
            return send_file(FORBIDDEN_HTML_FILE)
        return send_file(full_path)

    # Получаем список файлов и директорий
    files = os.listdir(full_path)
    files_list = []
    
    for file in files:
        # Используем функцию join_paths для формирования file_path
        file_path = join_paths(full_path, file)
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

    # Создаем временный HTML-файл для 403 ошибки
    create_forbidden_html()

    app.run(host='0.0.0.0', port=5000)
