# Dulce Camille - Sistema Contable, de Facturación e Inventario 🌸

¡Bienvenido al repositorio oficial de **Sistema contable e inventariado**! Esta es una aplicación móvil desarrollada en **Flutter** diseñada para gestionar el flujo contable, el control de inventario de prendas y la emisión de facturas de manera eficiente, rápida y segura.

---

## 🚀 Características Principales

* **Gestión de Inventario Inteligente:** Clasificación de productos por nombre, ID único, costos, precios de venta y existencias.
* **Módulo de Proveedores y Análisis de Ganancias:** Registro detallado de proveedores y sus costos de adquisición. El sistema calcula automáticamente un promedio de ganancias reales comparando los costos de compra frente a las ventas netas.
* **Historial y Emisión de Facturas:** Sección dedicada para revisar ventas realizadas.
* **Exportación a PDF:** Permite seleccionar cualquier factura del historial y descargarla directamente en formato PDF listo para imprimir.

---

## 🛠️ Arquitectura y Mejoras de Seguridad

Para garantizar un rendimiento óptimo y una experiencia de usuario fluida, el sistema incluye las siguientes características técnicas:

### 1. Base de Datos Local (SQLite)
Se implementó **SQLite** como motor de base de datos local debido a su excelente portabilidad, velocidad y autonomía, permitiendo que la aplicación funcione de manera local sin depender obligatoriamente de una conexión constante a internet.

### 2. Validaciones Estrictas de Datos
* **Control de Negativos:** El sistema bloquea automáticamente cualquier intento de registrar valores negativos en los montos de facturación o en el stock del inventario.
* **Correos Electrónicos Válidos:** El campo de correo electrónico exige una estructura real con un dominio válido (ej. `usuario@dominio.com`), evitando registros con texto al azar.
* **Cédula / Identificación:** Validación exclusiva para campos de identificación, asegurando que cumplan con los formatos numéricos y de longitud requeridos.

### 3. Experiencia de Usuario Mejorada (Gestos Rápidos)
Se eliminó la necesidad de entrar a cada factura para cambiar su estado de pago. Ahora cuenta con acciones mediante deslizamiento (*Dismissible Swipes*):
* 👉 **Deslizar a la derecha:** Marca la factura automáticamente como **Pagada**.
* 👈 **Deslizar a la izquierda (Solo si está pagada):** Muestra una ventana de confirmación preguntando al usuario: *¿Está seguro que quiere desmarcar la factura como pendiente?*.

---

## 🔮 Próximamente (Roadmap de Actualizaciones)

### 📊 Integración con Pistola Facturera (Lectora de Códigos de Barra)
Estamos trabajando para implementar soporte de hardware físico en la aplicación. 
* **Lectura Automatizada:** Conectar una pistola facturera para escanear etiquetas de código de barras.
* **Generación de ID Instantánea:** Al leer el código, el sistema generará automáticamente el ID del producto y lo agregará al inventario.
* **Clasificación Textil Rápida:** Optimización del inventario para clasificar las prendas de **Nuestro sistema de inventario** de manera masiva por **tallas, modelos y tipo de prenda** mediante el escaneo directo.

---

## 🛠️ Requisitos de Instalación

1. Asegúrate de tener instalado el SDK de [Flutter](https://flutter.dev/).
2. Clona este repositorio:
   ```bash
   git clone [https://github.com/LeonardoTapia7/Aplicaci-n-de-facturaci-n-inventario-y-ventas.git](https://github.com/LeonardoTapia7/Aplicaci-n-de-facturaci-n-inventario-y-ventas.git)
3. Navega a la carpeta del proyecto:

4. Bash
cd flutter_application_1
Instala las dependencias (incluyendo SQLite, path_provider y pdf):

5. Bash
flutter pub get
Ejecuta la aplicación:

6. Bash
flutter run

Desarrollado para el crecimiento de tu emprendimiento
