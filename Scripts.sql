-----
-- A mayúsculas en tabla cliente
-----
CREATE OR REPLACE TRIGGER tr_to_mayus_cliente 
BEFORE INSERT ON cliente 
FOR EACH ROW 
BEGIN 
    :NEW.nombre := UPPER(:NEW.nombre); 
    :NEW.apellido1 := UPPER(:NEW.apellido1); 
    :NEW.apellido2 := UPPER(:NEW.apellido2); 
    :NEW.domicilio := UPPER(:NEW.domicilio); 
END;

---


-----
-- A mayúsculas en tabla producto
-----
CREATE OR REPLACE TRIGGER tr_to_mayus_producto 
BEFORE INSERT ON producto 
FOR EACH ROW 
BEGIN 
    :NEW.descripcion := UPPER(:NEW.descripcion); 
END;




-----
-- Actualizar cliente: 
-----
CREATE OR REPLACE PROCEDURE pr_actualizar_cliente(
    p_rut       IN CLIENTE.rut%TYPE,
    p_atributo  IN VARCHAR2,
    p_valor     IN VARCHAR2
) AS
BEGIN
    IF p_atributo = 'NOMBRE' THEN
        UPDATE CLIENTE SET nombre = p_valor WHERE rut = p_rut;
    ELSIF p_atributo = 'APELLIDO1' THEN
        UPDATE CLIENTE SET apellido1 = p_valor WHERE rut = p_rut;
    ELSIF p_atributo = 'APELLIDO2' THEN
        UPDATE CLIENTE SET apellido2 = p_valor WHERE rut = p_rut;
    ELSIF p_atributo = 'DOMICILIO' THEN
        UPDATE CLIENTE SET domicilio = p_valor WHERE rut = p_rut;
    ELSIF p_atributo = 'TELEFONO' THEN
        UPDATE CLIENTE SET telefono = p_valor WHERE rut = p_rut;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Atributo no válido.');
        RETURN;
    END IF;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cliente actualizado correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al actualizar el cliente: ' || SQLERRM);
END pr_actualizar_cliente;



-----
-- Insertar cliente 
-----
CREATE OR REPLACE PROCEDURE insertar_cliente(
    p_rut VARCHAR2,
    p_nombre VARCHAR2,
    p_apellido1 VARCHAR2,
    p_apellido2 VARCHAR2,
    p_domicilio VARCHAR2,
    p_telefono VARCHAR2
) IS
BEGIN
    INSERT INTO cliente (rut, nombre, apellido1, apellido2, domicilio, telefono)
    VALUES (UPPER(p_rut), UPPER(p_nombre), UPPER(p_apellido1), UPPER(p_apellido2), UPPER(p_domicilio), p_telefono);
 
    COMMIT;
END insertar_cliente;



-----
-- consultar cliente 
-----
CREATE OR REPLACE FUNCTION fn_consulta_cliente(rutCliente CLIENTE.rut%TYPE)
        RETURN VARCHAR2
        IS  
cons      CLIENTE%ROWTYPE;            
consulta VARCHAR(200);

BEGIN
    SELECT * INTO cons
        FROM  CLIENTE
        WHERE rut = rutCliente;        
    consulta := cons.rut || 
                    '  ' || cons.nombre ||
                    '  ' || cons.apellido1||
                    '  ' ||cons.apellido2 ||
                    '  ' || cons.domicilio ||
                    '  ' || cons.telefono;
    RETURN consulta;
END fn_consulta_cliente;
-----
-- Ejecutable desde base como: 
-----
DECLARE
    resultado VARCHAR2(200);
BEGIN
    resultado := fn_consulta_cliente('12345678'); -- Reemplaza '12345678' con el RUT real del cliente
    DBMS_OUTPUT.PUT_LINE(resultado);
END;




-----
-- Reemplazar datos del cliente: 
-----
CREATE OR REPLACE PROCEDURE pr_actualiza_datos_cliente
  (rutCliente CLIENTE.rut%TYPE, nuevoNombre CLIENTE.nombre%TYPE, nuevoApellido1 CLIENTE.apellido1%TYPE, nuevoApellido2 CLIENTE.apellido2%TYPE, nuevoDomicilio CLIENTE.domicilio%TYPE, nuevoTelefono CLIENTE.telefono%TYPE)
IS
BEGIN
  UPDATE CLIENTE
  SET nombre = nuevoNombre,
      apellido1 = nuevoApellido1,
      apellido2 = nuevoApellido2,
      domicilio = nuevoDomicilio,
      telefono = nuevoTelefono
  WHERE rut = rutCliente;

  COMMIT;
END pr_actualiza_datos_cliente;
-----
-- Ejecutable desde base como: 
-----
BEGIN
    pr_actualiza_datos_cliente(
        rutCliente => '12345678',          -- Reemplaza con el RUT del cliente
        nuevoNombre => 'Nuevo Nombre',     -- Reemplaza con el nuevo nombre
        nuevoApellido1 => 'Nuevo Apellido1', -- Reemplaza con el nuevo primer apellido
        nuevoApellido2 => 'Nuevo Apellido2', -- Reemplaza con el nuevo segundo apellido (si aplica)
        nuevoDomicilio => 'Nueva Dirección', -- Reemplaza con el nuevo domicilio
        nuevoTelefono => '1234567890'       -- Reemplaza con el nuevo teléfono
    );
    COMMIT;
END;



-----
-- Modificar productos o artículos:
-----
CREATE OR REPLACE PROCEDURE modificar_producto (
    p_codigo          IN VARCHAR2,
    p_descripcion     IN VARCHAR2,
    p_precio_unitario IN NUMBER
)
AS
BEGIN
    UPDATE producto
    SET descripcion = p_descripcion,
        precio_unitario = p_precio_unitario
    WHERE codigo = p_codigo;
END modificar_producto;
-----
-- Ejecutable desde base como: 
-----
EXEC modificar_producto('codigo_producto', 'Nueva Descripción', nuevo_precio);
-----
-- Eliminar productos o artículos:
-----
CREATE OR REPLACE PROCEDURE eliminar_producto (
    p_codigo IN VARCHAR2
)
AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM venta
    WHERE producto_codigo = p_codigo;

    IF v_count = 0 THEN
        DELETE FROM producto
        WHERE codigo = p_codigo;
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'No se puede eliminar el producto porque existen ventas relacionadas.');
    END IF;
END eliminar_producto;

-----
-- Ejecutable desde base como: 
-----
EXEC eliminar_producto('codigo_producto');



-----
-- Consultar y listar procutos como tabla: 
-----
CREATE TYPE tipo_producto AS OBJECT (
    codigo VARCHAR2(5),
    descripcion VARCHAR2(100),
    precio_unitario NUMBER
);
/

CREATE TYPE tabla_producto AS TABLE OF tipo_producto;
/
CREATE OR REPLACE FUNCTION listar_productos RETURN tabla_producto
AS
    v_productos tabla_producto := tabla_producto();
BEGIN
    FOR registro IN (SELECT codigo, descripcion, precio_unitario FROM producto) LOOP
        v_productos.EXTEND;
        v_productos(v_productos.COUNT) := tipo_producto(registro.codigo, registro.descripcion, registro.precio_unitario);
    END LOOP;
    RETURN v_productos;
END listar_productos;
-----
-- ejecutar: 
-----
SELECT * FROM TABLE(listar_productos());


-----
-- Consultar y listar prodcutos individuales: 
-----
CREATE OR REPLACE PROCEDURE mostrar_producto_info(p_codigo VARCHAR2)
AS
    CURSOR cur_producto IS
        SELECT codigo, descripcion, precio_unitario
        FROM producto
        WHERE codigo = p_codigo;
    registro_producto cur_producto%ROWTYPE;
BEGIN
    OPEN cur_producto;
    FETCH cur_producto INTO registro_producto;

    IF cur_producto%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Código: ' || registro_producto.codigo);
        DBMS_OUTPUT.PUT_LINE('Descripción: ' || registro_producto.descripcion);
        DBMS_OUTPUT.PUT_LINE('Precio Unitario: ' || registro_producto.precio_unitario);
    ELSE
        DBMS_OUTPUT.PUT_LINE('No se encontró un producto con el código ' || p_codigo);
    END IF;

    CLOSE cur_producto;
END mostrar_producto_info;
-----
-- ejecutar: 
-----
EXEC mostrar_producto_info('codigo_del_producto');




-----
-- Recupera los datos de facturas de forma individual (incluye los datos de la factura, cliente, productos y ventas)
-----
CREATE OR REPLACE PROCEDURE pr_obtener_datos_factura (numero_factura IN VARCHAR2)
AS
CURSOR datos_factura_cur IS
    SELECT 
        f.numero AS Numero_Factura,
        f.fecha AS Fecha,
        f.subtotal AS Subtotal,
        f.iva AS IVA,
        f.total_factura AS Total_Factura,
        c.rut AS Rut_Cliente,
        c.nombre || ' ' || c.apellido1 || ' ' || NVL(c.apellido2, '') AS Nombre_Completo_Cliente,
        c.domicilio AS Domicilio,
        c.telefono AS Telefono,
        p.codigo AS Codigo_Producto,
        p.descripcion AS Descripcion_Producto,
        p.precio_unitario AS Precio_Unitario,
        v.cantidad AS Cantidad,
        v.total_venta AS Total_Venta
    FROM factura f
    JOIN cliente c ON f.cliente_rut = c.rut
    JOIN venta v ON f.numero = v.factura_numero
    JOIN producto p ON v.producto_codigo = p.codigo
    WHERE f.numero = numero_factura;
BEGIN
    FOR registro IN datos_factura_cur LOOP
        DBMS_OUTPUT.PUT_LINE('Factura Número: ' || registro.Numero_Factura);
        DBMS_OUTPUT.PUT_LINE('Fecha: ' || registro.Fecha);
        DBMS_OUTPUT.PUT_LINE('Subtotal: ' || registro.Subtotal);
        DBMS_OUTPUT.PUT_LINE('IVA: ' || registro.IVA);
        DBMS_OUTPUT.PUT_LINE('Total Factura: ' || registro.Total_Factura);
        DBMS_OUTPUT.PUT_LINE('Cliente RUT: ' || registro.Rut_Cliente);
        DBMS_OUTPUT.PUT_LINE('Nombre Completo del Cliente: ' || registro.Nombre_Completo_Cliente);
        DBMS_OUTPUT.PUT_LINE('Producto Código: ' || registro.Codigo_Producto);
        DBMS_OUTPUT.PUT_LINE('Descripción Producto: ' || registro.Descripcion_Producto);
        DBMS_OUTPUT.PUT_LINE('Cantidad: ' || registro.Cantidad);
        DBMS_OUTPUT.PUT_LINE('Total Venta: ' || registro.Total_Venta);
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontraron datos para la factura: ' || numero_factura);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END pr_obtener_datos_factura;
-----
-- Ejecutable desde base como: 
-----
EXEC pr_obtener_datos_factura('A2301'); -- Usar un número de factura real y existente. 


