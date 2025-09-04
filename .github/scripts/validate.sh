#!/bin/bash

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0;0m' # Sin color

echo "-------------------------------------------"
echo "🚀 Iniciando validación de Laboratorio 1..."
echo "-------------------------------------------"

# --- PASO 1: VERIFICAR LA ESTRUCTURA DE ARCHIVOS REQUERIDA ---
echo "✅ PASO 1: Verificando estructura de archivos..."
# NOTA: Se ha corregido el typo "mode" a "model" según la convención estándar.
BASE_PATH="src/main/java/org/laboratorio1"
PRODUCTO_FILE="$BASE_PATH/model/Producto.java"
SERVICIO_FILE="$BASE_PATH/service/ServicioInventario.java"
MAIN_FILE="$BASE_PATH/controller/Main.java"

if [ ! -f "$PRODUCTO_FILE" ] || [ ! -f "$SERVICIO_FILE" ] || [ ! -f "$MAIN_FILE" ]; then
    echo -e "${RED}❌ ERROR: Estructura de archivos incorrecta.${NC}"
    echo "Asegúrate de que existan los siguientes archivos en sus paquetes correctos:"
    [ ! -f "$PRODUCTO_FILE" ] && echo "  - Falta: $PRODUCTO_FILE (Se esperaba en paquete 'model')"
    [ ! -f "$SERVICIO_FILE" ] && echo "  - Falta: $SERVICIO_FILE"
    [ ! -f "$MAIN_FILE" ] && echo "  - Falta: $MAIN_FILE"
    exit 1
fi
echo -e "${GREEN}Estructura de archivos correcta.${NC}"


# --- PASO 2: CREAR EL TEST RUNNER PARA VALIDAR LA LÓGICA ---
echo "✅ PASO 2: Creando el entorno de pruebas..."
cat <<EOF > TestRunner.java
import org.laboratorio1.model.Producto;
import org.laboratorio1.service.ServicioInventario;
import java.util.ArrayList;

public class TestRunner {
    public static void main(String[] args) {
        boolean allTestsPassed = true;

        // Prueba 1: Verificar la clase Producto (constructor, getters, setters)
        try {
            Producto p = new Producto("SKU01", "Laptop", 1200.50, 10);
            p.setCantidadStock(15);
            if (!p.getSku().equals("SKU01") || !p.getNombre().equals("Laptop") || p.getPrecio() != 1200.50 || p.getCantidadStock() != 15) {
                System.out.println("❌ TEST 1 FALLIDO: La clase Producto (constructor, getters o setters) no funciona como se esperaba.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 1 APROBADO: La clase Producto funciona correctamente.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 1 FALLIDO: Error crítico al usar la clase Producto. " + e.getMessage());
            allTestsPassed = false;
        }

        // Prueba 2: Verificar ServicioInventario.venderProducto() - Venta Exitosa
        try {
            ServicioInventario servicio = new ServicioInventario();
            Producto pVenta = new Producto("SKU02", "Mouse", 25.0, 20);
            servicio.agregarProducto(pVenta);
            boolean ventaExitosa = servicio.venderProducto("SKU02", 5);
            if (!ventaExitosa || pVenta.getCantidadStock() != 15) {
                System.out.println("❌ TEST 2 FALLIDO: Una venta exitosa no retornó 'true' o no actualizó el stock correctamente.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 2 APROBADO: El método venderProducto() (venta exitosa) funciona.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 2 FALLIDO: Error en venderProducto() en una venta exitosa. " + e.getMessage());
            allTestsPassed = false;
        }

        // Prueba 3: Verificar ServicioInventario.venderProducto() - Venta Fallida (sin stock)
        try {
            ServicioInventario servicio = new ServicioInventario();
            Producto pVenta = new Producto("SKU03", "Teclado", 80.0, 5);
            servicio.agregarProducto(pVenta);
            boolean ventaFallida = servicio.venderProducto("SKU03", 10);
            if (ventaFallida || pVenta.getCantidadStock() != 5) {
                System.out.println("❌ TEST 3 FALLIDO: Una venta sin stock suficiente no retornó 'false' o modificó el stock indebidamente.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 3 APROBADO: El método venderProducto() (venta fallida) funciona.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 3 FALLIDO: Error en venderProducto() en una venta fallida. " + e.getMessage());
            allTestsPassed = false;
        }

        // Prueba 4: Verificar ServicioInventario.calcularValorTotalInventario()
        try {
            ServicioInventario servicio = new ServicioInventario();
            servicio.agregarProducto(new Producto("P1", "Prod A", 100.0, 10)); // Valor: 1000
            servicio.agregarProducto(new Producto("P2", "Prod B", 50.0, 20));  // Valor: 1000
            // Subtotal = 2000. Total con 13% IVA = 2000 * 1.13 = 2260.0
            double valorTotal = servicio.calcularValorTotalInventario();
            if (Math.abs(valorTotal - 2260.0) > 0.001) { // Comparar doubles con margen de error
                System.out.println("❌ TEST 4 FALLIDO: El cálculo del valor total del inventario (con IVA) es incorrecto. Se esperaba 2260.0.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 4 APROBADO: El método calcularValorTotalInventario() funciona.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 4 FALLIDO: Error en calcularValorTotalInventario(). " + e.getMessage());
            allTestsPassed = false;
        }

        if (!allTestsPassed) {
            System.exit(1);
        }
    }
}
EOF
echo -e "${GREEN}Entorno de pruebas creado.${NC}"

# --- PASO 3: COMPILAR TODO EL PROYECTO ---
echo "✅ PASO 3: Compilando todo el código fuente..."
mkdir -p bin
COMPILE_OUTPUT=$(javac -d bin $(find . -name "*.java") 2>&1)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR DE COMPILACIÓN. Revisa tu código.${NC}"
    echo "$COMPILE_OUTPUT"
    exit 1
fi
echo -e "${GREEN}Compilación exitosa.${NC}"

# --- PASO 4: EJECUTAR LAS PRUEBAS ---
echo "✅ PASO 4: Ejecutando pruebas de lógica..."
java -cp bin TestRunner
TEST_RESULT=$?

# --- PASO 5: MOSTRAR RESULTADO FINAL ---
echo "-------------------------------------------"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Verificación completada. Todos los tests pasaron exitosamente.${NC}"
    echo "Tu entrega ha sido recibida y procesada."
    exit 0
else
    echo -e "${RED}❌ Se encontraron errores durante la validación.${NC}"
    echo "Revisa los detalles de los tests en la salida anterior para identificar las inconsistencias."
    exit 1
fi