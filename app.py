from flask import Flask, render_template, request, redirect, url_for, session, jsonify, flash
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
import os
from supabase import create_client, Client
from dotenv import load_dotenv
import base64
from functools import wraps

load_dotenv()

app = Flask(__name__)
app.secret_key = 'poli-biblioteca-secret-key-2024'
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Configuración de Supabase
SUPABASE_URL = os.getenv('VITE_SUPABASE_URL')
SUPABASE_KEY = os.getenv('VITE_SUPABASE_ANON_KEY')
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Credenciales admin (en producción usar base de datos)
ADMIN_USERNAME = 'admin'
ADMIN_PASSWORD = 'admin123'  # Cambiar en producción

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_logged_in' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    try:
        # Obtener todos los libros
        response = supabase.table('libros').select('*').order('titulo').execute()
        libros = response.data

        # Obtener categorías únicas
        categorias = list(set([libro['categoria'] for libro in libros]))
        categorias.sort()

        return render_template('index.html', libros=libros, categorias=categorias)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('index.html', libros=[], categorias=[])

@app.route('/libro/<libro_id>')
def detalle_libro(libro_id):
    try:
        response = supabase.table('libros').select('*').eq('id', libro_id).single().execute()
        libro = response.data
        return render_template('detalle.html', libro=libro)
    except Exception as e:
        print(f"Error: {e}")
        flash('Libro no encontrado', 'error')
        return redirect(url_for('index'))

@app.route('/buscar')
def buscar():
    query = request.args.get('q', '')
    categoria = request.args.get('categoria', '')

    try:
        libros_query = supabase.table('libros').select('*')

        if query:
            libros_query = libros_query.or_(f'titulo.ilike.%{query}%,autores.ilike.%{query}%,referencia.ilike.%{query}%')

        if categoria:
            libros_query = libros_query.eq('categoria', categoria)

        response = libros_query.order('titulo').execute()
        libros = response.data

        # Obtener categorías para el filtro
        all_response = supabase.table('libros').select('categoria').execute()
        categorias = list(set([libro['categoria'] for libro in all_response.data]))
        categorias.sort()

        return render_template('buscar.html', libros=libros, query=query, categoria=categoria, categorias=categorias)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('buscar.html', libros=[], query=query, categoria=categoria, categorias=[])

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            session['admin_logged_in'] = True
            flash('Inicio de sesión exitoso', 'success')
            return redirect(url_for('admin_panel'))
        else:
            flash('Usuario o contraseña incorrectos', 'error')

    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('admin_logged_in', None)
    flash('Sesión cerrada correctamente', 'success')
    return redirect(url_for('index'))

@app.route('/admin')
@login_required
def admin_panel():
    try:
        response = supabase.table('libros').select('*').order('created_at', desc=True).execute()
        libros = response.data
        return render_template('admin.html', libros=libros)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('admin.html', libros=[])

@app.route('/admin/agregar', methods=['GET', 'POST'])
@login_required
def agregar_libro():
    if request.method == 'POST':
        try:
            referencia = request.form.get('referencia')
            titulo = request.form.get('titulo')
            autores = request.form.get('autores')
            categoria = request.form.get('categoria')
            num_paginas = int(request.form.get('num_paginas'))
            cantidad_ejemplares = int(request.form.get('cantidad_ejemplares'))

            imagen_url = None
            if 'imagen' in request.files:
                file = request.files['imagen']
                if file and file.filename and allowed_file(file.filename):
                    # Leer la imagen y convertirla a base64
                    imagen_bytes = file.read()
                    imagen_base64 = base64.b64encode(imagen_bytes).decode('utf-8')
                    imagen_url = f"data:image/{file.filename.rsplit('.', 1)[1].lower()};base64,{imagen_base64}"

            # Insertar en Supabase
            data = {
                'referencia': referencia,
                'titulo': titulo,
                'autores': autores,
                'categoria': categoria,
                'num_paginas': num_paginas,
                'cantidad_ejemplares': cantidad_ejemplares,
                'imagen_url': imagen_url
            }

            response = supabase.table('libros').insert(data).execute()

            flash('Libro agregado exitosamente', 'success')
            return redirect(url_for('admin_panel'))
        except Exception as e:
            print(f"Error: {e}")
            flash(f'Error al agregar libro: {str(e)}', 'error')

    return render_template('agregar_libro.html')

@app.route('/admin/editar/<libro_id>', methods=['GET', 'POST'])
@login_required
def editar_libro(libro_id):
    try:
        if request.method == 'POST':
            referencia = request.form.get('referencia')
            titulo = request.form.get('titulo')
            autores = request.form.get('autores')
            categoria = request.form.get('categoria')
            num_paginas = int(request.form.get('num_paginas'))
            cantidad_ejemplares = int(request.form.get('cantidad_ejemplares'))

            # Obtener la imagen actual
            current_libro = supabase.table('libros').select('imagen_url').eq('id', libro_id).single().execute()
            imagen_url = current_libro.data.get('imagen_url')

            # Si hay una nueva imagen, procesarla
            if 'imagen' in request.files:
                file = request.files['imagen']
                if file and file.filename and allowed_file(file.filename):
                    imagen_bytes = file.read()
                    imagen_base64 = base64.b64encode(imagen_bytes).decode('utf-8')
                    imagen_url = f"data:image/{file.filename.rsplit('.', 1)[1].lower()};base64,{imagen_base64}"

            # Actualizar en Supabase
            data = {
                'referencia': referencia,
                'titulo': titulo,
                'autores': autores,
                'categoria': categoria,
                'num_paginas': num_paginas,
                'cantidad_ejemplares': cantidad_ejemplares,
                'imagen_url': imagen_url
            }

            response = supabase.table('libros').update(data).eq('id', libro_id).execute()

            flash('Libro actualizado exitosamente', 'success')
            return redirect(url_for('admin_panel'))

        # GET request
        response = supabase.table('libros').select('*').eq('id', libro_id).single().execute()
        libro = response.data
        return render_template('editar_libro.html', libro=libro)
    except Exception as e:
        print(f"Error: {e}")
        flash('Error al editar libro', 'error')
        return redirect(url_for('admin_panel'))

@app.route('/admin/eliminar/<libro_id>', methods=['POST'])
@login_required
def eliminar_libro(libro_id):
    try:
        response = supabase.table('libros').delete().eq('id', libro_id).execute()
        flash('Libro eliminado exitosamente', 'success')
    except Exception as e:
        print(f"Error: {e}")
        flash('Error al eliminar libro', 'error')

    return redirect(url_for('admin_panel'))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
