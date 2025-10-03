# Sistema de Biblioteca - Politécnico Colombiano Jaime Isaza Cadavid

Sistema de gestión de biblioteca desarrollado en Python con Flask, siguiendo los lineamientos de identidad visual del Politécnico Colombiano.

## Características

- **Gestión de Libros**: Agregar, editar y eliminar libros con sus detalles completos
- **Catálogo Visual**: Navegación intuitiva con imágenes de portada de libros
- **Búsqueda Avanzada**: Buscar por título, autor, referencia o categoría
- **Panel de Administración**: Sistema completo para gestionar el catálogo
- **Diseño Responsivo**: Adaptable a dispositivos móviles, tablets y escritorio
- **Colores Institucionales**: Verde (#009240) y Amarillo (#FFD400) del Politécnico
- **Animaciones Suaves**: Transiciones y efectos visuales modernos

## Tecnologías Utilizadas

- **Backend**: Python 3.x + Flask
- **Base de Datos**: Supabase (PostgreSQL)
- **Frontend**: HTML5, CSS3, JavaScript
- **Diseño**: Siguiendo el Manual de Identidad Gráfica Institucional

## Instalación

### 1. Instalar Python y dependencias

```bash
# Asegúrate de tener Python 3.8 o superior instalado
python --version

# Instalar dependencias
pip install -r requirements.txt
```

### 2. Configurar variables de entorno

El archivo `.env` ya está configurado con las credenciales de Supabase.

### 3. Iniciar la aplicación

```bash
python app.py
```

La aplicación estará disponible en: `http://localhost:5000`

## Credenciales de Administrador

- **Usuario**: admin
- **Contraseña**: admin123

**IMPORTANTE**: Cambiar estas credenciales en producción editando el archivo `app.py`.

## Estructura del Proyecto

```
proyecto/
├── app.py                  # Aplicación principal Flask
├── requirements.txt        # Dependencias Python
├── .env                    # Variables de entorno
├── static/
│   ├── css/
│   │   └── styles.css     # Estilos institucionales
│   ├── js/
│   │   └── main.js        # JavaScript para interactividad
│   └── img/
│       └── 2.png          # Escudo del Politécnico
├── templates/
│   ├── base.html          # Plantilla base
│   ├── index.html         # Página principal
│   ├── detalle.html       # Detalle de libro
│   ├── buscar.html        # Búsqueda de libros
│   ├── login.html         # Login administrativo
│   ├── admin.html         # Panel de administración
│   ├── agregar_libro.html # Formulario agregar libro
│   └── editar_libro.html  # Formulario editar libro
└── uploads/               # Directorio para imágenes (opcional)
```

## Uso del Sistema

### Para Usuarios

1. **Navegación**: Explora el catálogo desde la página principal
2. **Búsqueda**: Usa el buscador para encontrar libros específicos
3. **Categorías**: Filtra libros por categoría
4. **Detalles**: Haz clic en cualquier libro para ver información completa

### Para Administradores

1. **Login**: Accede con las credenciales de admin
2. **Agregar Libros**:
   - Click en "Agregar Nuevo Libro"
   - Completa el formulario con todos los datos
   - Opcionalmente, sube una foto de la portada
3. **Editar Libros**:
   - En el panel admin, click en el ícono de editar (✏️)
   - Modifica los campos necesarios
   - Guarda los cambios
4. **Eliminar Libros**:
   - Click en el ícono de eliminar (🗑️)
   - Confirma la eliminación

## Características del Diseño

### Colores Institucionales

- **Verde Principal**: #009240
- **Verde Oscuro**: #00734C
- **Verde Claro**: #25B322
- **Amarillo Principal**: #FFD400
- **Amarillo Claro**: #FFE106
- **Amarillo Oscuro**: #FFAA00

### Tipografía

- Se recomienda usar la familia AmsiPro (según manual institucional)
- Fallback: Segoe UI, sans-serif

### Animaciones

- Transiciones suaves en hover
- Animaciones de entrada para contenido
- Efectos visuales en cards y botones

## Base de Datos

La base de datos está alojada en Supabase con la siguiente estructura:

### Tabla: libros

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | uuid | ID único (PK) |
| referencia | text | Código de referencia único |
| titulo | text | Título del libro |
| autores | text | Autores del libro |
| categoria | text | Categoría temática |
| num_paginas | integer | Número de páginas |
| cantidad_ejemplares | integer | Ejemplares disponibles |
| imagen_url | text | URL de imagen (Base64) |
| created_at | timestamptz | Fecha de creación |
| updated_at | timestamptz | Fecha de actualización |

## Funcionalidades Adicionales

- **RLS (Row Level Security)**: Políticas de seguridad en la base de datos
- **Imágenes en Base64**: Las fotos se guardan directamente en la BD
- **Mensajes Flash**: Notificaciones de éxito/error
- **Validación de Formularios**: Campos requeridos y tipos de datos
- **Responsive Design**: Adaptable a todos los tamaños de pantalla

## Mejoras Futuras Sugeridas

- Sistema de préstamos de libros
- Historial de transacciones
- Usuarios con diferentes roles
- Reportes y estadísticas avanzadas
- Sistema de reservas en línea
- Integración con código de barras/QR
- Exportación a PDF/Excel
- API REST para integraciones

## Soporte

Para dudas o soporte técnico, contactar a:
- Oficina Asesora de Comunicaciones
- Politécnico Colombiano Jaime Isaza Cadavid

## Licencia

Sistema desarrollado para uso exclusivo del Politécnico Colombiano Jaime Isaza Cadavid.
© 2025 - Todos los derechos reservados.
