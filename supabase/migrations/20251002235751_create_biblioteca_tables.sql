/*
  # Sistema de Gestión de Biblioteca - Politécnico Colombiano

  ## Tablas Creadas
  - `libros`: Almacena información de libros con posibilidad de subir foto de portada
    - `id` (uuid, primary key)
    - `referencia` (text, único): Código de referencia del libro
    - `titulo` (text): Título del libro
    - `autores` (text): Autores del libro
    - `categoria` (text): Categoría temática
    - `num_paginas` (integer): Número de páginas
    - `cantidad_ejemplares` (integer): Cantidad disponible
    - `imagen_url` (text): URL de la imagen de portada
    - `created_at` (timestamptz): Fecha de registro
    - `updated_at` (timestamptz): Fecha de actualización

  ## Seguridad
  - RLS habilitado en la tabla libros
  - Políticas de seguridad para lectura pública y escritura autenticada
*/

-- Crear tabla de libros
CREATE TABLE IF NOT EXISTS libros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referencia text UNIQUE NOT NULL,
  titulo text NOT NULL,
  autores text NOT NULL,
  categoria text NOT NULL,
  num_paginas integer NOT NULL CHECK (num_paginas > 0),
  cantidad_ejemplares integer NOT NULL DEFAULT 1 CHECK (cantidad_ejemplares >= 0),
  imagen_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE libros ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden ver los libros (lectura pública)
CREATE POLICY "Permitir lectura pública de libros"
  ON libros FOR SELECT
  TO public
  USING (true);

-- Política: Solo usuarios autenticados pueden insertar libros
CREATE POLICY "Usuarios autenticados pueden insertar libros"
  ON libros FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política: Solo usuarios autenticados pueden actualizar libros
CREATE POLICY "Usuarios autenticados pueden actualizar libros"
  ON libros FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Política: Solo usuarios autenticados pueden eliminar libros
CREATE POLICY "Usuarios autenticados pueden eliminar libros"
  ON libros FOR DELETE
  TO authenticated
  USING (true);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_libros_categoria ON libros(categoria);
CREATE INDEX IF NOT EXISTS idx_libros_titulo ON libros(titulo);
CREATE INDEX IF NOT EXISTS idx_libros_referencia ON libros(referencia);

-- Función para actualizar el campo updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_libros_updated_at BEFORE UPDATE ON libros
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insertar datos de ejemplo
INSERT INTO libros (referencia, titulo, autores, categoria, num_paginas, cantidad_ejemplares) VALUES
('LIT-001', 'Cien Años de Soledad', 'Gabriel García Márquez', 'Literatura', 471, 15),
('LIT-002', 'La Casa de los Espíritus', 'Isabel Allende', 'Literatura', 433, 10),
('TEC-001', 'The Art of Computer Programming Vol. 1', 'Donald Knuth', 'Tecnología', 672, 5),
('TEC-002', 'Clean Code', 'Robert C. Martin', 'Tecnología', 464, 20),
('CIE-001', 'Breve Historia del Tiempo', 'Stephen Hawking', 'Ciencia', 256, 12),
('HIS-001', 'Sapiens: De Animales a Dioses', 'Yuval Noah Harari', 'Historia', 498, 18)
ON CONFLICT (referencia) DO NOTHING;
