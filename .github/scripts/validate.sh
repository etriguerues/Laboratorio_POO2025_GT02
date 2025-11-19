#!/bin/bash
export LANG=C.UTF-8

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;0m' # Sin color

echo "--------------------------------------------------------"
echo "Iniciando validación Lab 4: Black Friday (Callable & Futures)"
echo "--------------------------------------------------------"

# Variable de control de errores
FAILED=0

# --- CONFIGURACIÓN DE RUTA ---
BASE_PATH="src/main/java/com/poo/lab4"

echo -e "Buscando código fuente en: $BASE_PATH"

# --- PASO 1: VERIFICAR ESTRUCTURA DE PAQUETES Y ARCHIVOS ---
echo -e "\n${YELLOW}PASO 1: Verificando estructura (Model, Task, Main)...${NC}"

REQUIRED_PATHS=(
    "$BASE_PATH/model"
    "$BASE_PATH/task"
    "$BASE_PATH/main"
    "$BASE_PATH/model/Producto.java"
    "$BASE_PATH/task/ClienteCallable.java"
    "$BASE_PATH/main/MainEcommerce.java"
)

STRUCTURE_OK=true
for path in "${REQUIRED_PATHS[@]}"; do
    if [[ "$path" != *.java && ! -d "$path" ]]; then
        echo -e "${RED}[FALTA RUTA] No encontrada: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    elif [[ "$path" == *.java && ! -f "$path" ]]; then
        echo -e "${RED}[FALTA ARCHIVO] No encontrado: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = true ]; then
    echo -e "${GREEN}Estructura de paquetes y clases correcta.${NC}"
fi

# --- PASO 2: VERIFICAR REQUISITOS TÉCNICOS (RUBRICA) ---
echo -e "\n${YELLOW}PASO 2: Verificando lógica de Concurrencia (Callable/Synch)...${NC}"

if [ ! -d "$BASE_PATH" ]; then
    echo -e "${RED}Directorio base no encontrado. Abortando validación lógica.${NC}"
    exit 1
fi

# 2.1 Validar Producto.java (Sincronización obligatoria)
PRODUCT_FILE="$BASE_PATH/model/Producto.java"
if [ -f "$PRODUCT_FILE" ]; then
    # Verificamos que el método reducirStock exista y sea synchronized
    if grep -q "reducirStock" "$PRODUCT_FILE"; then
        if ! grep -q "synchronized.*reducirStock" "$PRODUCT_FILE" && ! grep -q "reducirStock.*synchronized" "$PRODUCT_FILE"; then
            echo -e "${RED}[ERROR CRÍTICO] Producto.java: El método 'reducirStock' NO es 'synchronized'. Esto causará errores de inventario.${NC}"
            FAILED=1
        fi
    else
        echo -e "${RED}[ERROR] Producto.java: No se encontró el método 'reducirStock'.${NC}"
        FAILED=1
    fi
fi

# 2.2 Validar ClienteCallable.java (Debe ser Callable, no Runnable)
TASK_FILE="$BASE_PATH/task/ClienteCallable.java"
if [ -f "$TASK_FILE" ]; then
    if ! grep -q "implements Callable" "$TASK_FILE"; then
        echo -e "${RED}[ERROR] ClienteCallable: Debe implementar 'Callable' (para retornar resultado), no Runnable.${NC}"
        FAILED=1
    fi
    if ! grep -q "call()" "$TASK_FILE"; then
        echo -e "${RED}[ERROR] ClienteCallable: No se encontró el método 'call()' sobrescrito.${NC}"
        FAILED=1
    fi
fi

# 2.3 Validar MainEcommerce.java (Manejo de Futures y Gson)
MAIN_FILE="$BASE_PATH/main/MainEcommerce.java"
if [ -f "$MAIN_FILE" ]; then
    # Verificar ExecutorService
    if ! grep -q "ExecutorService" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] Main: No se usa 'ExecutorService' para gestionar los hilos.${NC}"
        FAILED=1
    fi
    # Verificar Futures
    if ! grep -q "Future<" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] Main: No se está usando 'Future' para capturar la respuesta de los clientes.${NC}"
        FAILED=1
    fi
    # Verificar Gson (JSON final)
    if ! grep -q "Gson" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] Main: No se encontró la librería Gson para guardar el inventario final.${NC}"
        FAILED=1
    fi
fi

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Lógica de concurrencia (Synchronized, Callable, Future) correcta.${NC}"
fi

# --- PASO 4: COMPILAR PROYECTO (MAVEN) ---
echo -e "\n${YELLOW}PASO 4: Compilando proyecto...${NC}"

COMPILE_OUTPUT=$(mvn clean package -DskipTests 2>&1)
MVN_EXIT_CODE=$?

if [ $MVN_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}ERROR DE COMPILACIÓN.${NC}"
    echo "Posibles causas: Mal uso de Generics en Future<T>, falta de try/catch en call(), o falta Gson."
    echo "$COMPILE_OUTPUT" | grep -E "ERROR|FAILURE" -A 2 | head -n 10
    FAILED=1
else
    echo -e "${GREEN}Compilación exitosa.${NC}"
fi

# --- RESULTADO FINAL ---
echo -e "\n--------------------------------------------------------"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✔ LABORATORIO APROBADO${NC}"
    echo "Estructura correcta, manejo de concurrencia seguro y persistencia implementada."
    exit 0
else
    echo -e "${RED}✘ REVISAR ERRORES${NC}"
    echo "El laboratorio no cumple con todos los criterios de la rúbrica."
    exit 1
fi
