-- ========================================
-- PASO FIRME - ESQUEMA DE BASE DE DATOS (Supabase)
-- ========================================
-- Ejecutar en el SQL Editor de Supabase

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    imagen_url TEXT,
    categoria TEXT NOT NULL,
    stock INTEGER DEFAULT 0,
    descripcion TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de reseñas
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre_usuario TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comentario TEXT NOT NULL,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de administradores (emails autorizados)
CREATE TABLE IF NOT EXISTS admin_emails (
    email TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);
CREATE INDEX IF NOT EXISTS idx_reviews_approved ON reviews(approved);
CREATE INDEX IF NOT EXISTS idx_reviews_created ON reviews(created_at DESC);

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para productos
CREATE TRIGGER update_productos_updated_at
    BEFORE UPDATE ON productos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security)
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_emails ENABLE ROW LEVEL SECURITY;

-- Políticas públicas
CREATE POLICY "Anyone can view products" ON productos
    FOR SELECT USING (true);

CREATE POLICY "Anyone can view approved reviews" ON reviews
    FOR SELECT USING (approved = true);

CREATE POLICY "Authenticated users can insert reviews" ON reviews
    FOR INSERT WITH CHECK (true);

-- Políticas para administradores (basadas en admin_emails)
CREATE POLICY "Admins can manage products" ON productos
    FOR ALL USING (auth.email() IN (SELECT email FROM admin_emails));

CREATE POLICY "Admins can manage reviews" ON reviews
    FOR ALL USING (auth.email() IN (SELECT email FROM admin_emails));

CREATE POLICY "Admins can read admin_emails" ON admin_emails
    FOR SELECT USING (auth.email() IN (SELECT email FROM admin_emails));

-- Datos de ejemplo
INSERT INTO admin_emails (email) VALUES ('erneg442@gmail.com')
    ON CONFLICT (email) DO NOTHING;

INSERT INTO productos (nombre, precio, imagen_url, categoria) VALUES
    ('Camisa Oxford Azul', 4500, 'https://images.pexels.com/photos/5654474/pexels-photo-5654474.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop', 'camisas'),
    ('Pantalón Gris Formal', 6500, 'https://images.pexels.com/photos/1598507/pexels-photo-1598507.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop', 'pantalones'),
    ('Short Beige Casual', 3500, 'https://images.pexels.com/photos/1081685/pexels-photo-1081685.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop', 'shorts'),
    ('Sneakers Blancos', 8500, 'https://images.pexels.com/photos/1598505/pexels-photo-1598505.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop', 'zapatos'),
    ('Conjunto Niña Amarillo', 4200, 'https://images.pexels.com/photos/1103831/pexels-photo-1103831.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop', 'ninos')
ON CONFLICT DO NOTHING;

INSERT INTO reviews (nombre_usuario, rating, comentario, approved) VALUES
    ('María G.', 5, 'Excelente calidad y atención. Los zapatos son increíbles.', true),
    ('Carlos R.', 4, 'La ropa es de primera, volveré a comprar.', true),
    ('Ana L.', 5, 'Diseños únicos, me encanta su estilo.', true),
    ('Pedro S.', 5, 'Muy contento con mi compra, envío rápido.', false)
ON CONFLICT DO NOTHING;