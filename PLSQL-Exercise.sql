ALTER SESSION SET "_ORACLE_SCRIPT" = true;

SET SERVEROUTPUT ON;

---------------------------------------------------------------
-- 1)   GESTIÓN DE USUARIOS Y TABLAS --------------------------
---------------------------------------------------------------
-- 1. Usuario "GESTOR"
--Creamos el usuario y le añadimos los permisos pertinentes
CREATE USER GESTOR IDENTIFIED BY 1234;
GRANT CREATE SESSION TO GESTOR;
GRANT ALTER ON ILERNA_PAC.ASIGNATURAS_PAC TO GESTOR;
GRANT ALTER ON ILERNA_PAC.ALUMNOS_PAC TO GESTOR;

--Modificamos las tablas
ALTER TABLE ILERNA_PAC.ALUMNOS_PAC ADD CIUDAD VARCHAR(30);
ALTER TABLE ILERNA_PAC.ASIGNATURAS_PAC MODIFY NOMBRE_PROFESOR VARCHAR(50);
ALTER TABLE ILERNA_PAC.ASIGNATURAS_PAC DROP COLUMN CREDITOS;
ALTER TABLE ILERNA_PAC.ASIGNATURAS_PAC ADD CICLO VARCHAR(3);

-- 2. Usuario "DIRECTOR"
--Creamos el usuario
CREATE USER DIRECTOR IDENTIFIED BY 1234;
--Creamos el rol
CREATE ROLE ROL_DIRECTOR;
--Asignamos al rol los permisos pertinentes
GRANT CREATE SESSION TO ROL_DIRECTOR;
GRANT INSERT, SELECT, UPDATE ON ILERNA_PAC.ASIGNATURAS_PAC TO ROL_DIRECTOR;
GRANT INSERT, SELECT, UPDATE ON ILERNA_PAC.ALUMNOS_PAC TO ROL_DIRECTOR;
--Asignamos a DIRECTOR el rol ROL_DIRECTOR
GRANT ROL_DIRECTOR TO DIRECTOR;
--Añadimos dos filas nuevas y actualizamos ciclo
INSERT INTO ILERNA_PAC.ALUMNOS_PAC VALUES ('MASAGA', 'María', 'Salazar García-Rosales', 29, 'Madrid');
INSERT INTO ILERNA_PAC.ASIGNATURAS_PAC VALUES ('DAX_M02B', 'MP2.Bases de datos B', 'Claudi Godia', 'DAX');
UPDATE ILERNA_PAC.ASIGNATURAS_PAC SET CICLO = 'DAW';

---------------------------------------------------------------
-- 2)	BLOQUES ANONIMOS -------------------------------------- 
---------------------------------------------------------------

-- 1. TABLA DE MULTIPLICAR
DECLARE
--Declaramos las variables necesarias
tabladel NUMBER(2) := 9;
aux NUMBER(2) := 1;
multiplicado NUMBER;
BEGIN
--Iniciamos el bucle que seguirá hasta que la variable aux sea igual o menor que 11
--y en cada iteración le añadimos uno para que vaya haciendo la tabla de multiplicar
    WHILE aux <= 11 LOOP
        multiplicado := tabladel * aux;
        DBMS_OUTPUT.PUT_LINE(tabladel || ' x ' || aux || ' = ' || multiplicado );
        aux := aux + 1;
    END LOOP;
END;
/

-- 2. %IRPF SALARIO BRUTO ANUAL
DECLARE
--Declaramos las variables necesarias para hacer los cálculos
    salario_mes NUMBER(10, 2) := 1000;
    salario_anual NUMBER(10, 2);
    IRPF_porcentaje NUMBER(2, 2);
    IRPF_porcentaje_limpio NUMBER(2);
    IRPF_total NUMBER(10,2);
BEGIN
--Multiplicamos por 12 el salario_mes para obtener el salario_anual
    salario_anual := salario_mes * 12;
--Hacemos una consulta para obtener el porcentaje de IRPF de ese salario anual
    SELECT PORCENTAJE INTO IRPF_porcentaje
    FROM ILERNA_PAC.IRPF_PAC
    WHERE valor_bajo < salario_anual AND valor_alto > salario_anual;
--Multiplicamos por 100 el procentaje para obtener el valor entero
    IRPF_total := salario_anual * IRPF_porcentaje;
    IRPF_porcentaje_limpio := IRPF_porcentaje * 100;
--Imprimimos los valores
    DBMS_OUTPUT.PUT_LINE('Salario mensual: ' || salario_mes || ' €');
    DBMS_OUTPUT.PUT_LINE('Salario anual: ' || salario_anual || ' €');
    DBMS_OUTPUT.PUT_LINE('IRPF aplicado: ' || IRPF_porcentaje_limpio || '%');
    DBMS_OUTPUT.PUT_LINE('IRP a pagar = ' || IRPF_total || ' €');
END;
/

---------------------------------------------------------------
-- 3)	PROCEDIMIENTOS Y FUNCIONES SIMPLES -------------------- 
---------------------------------------------------------------

-- 1. SUMA IMPARES
--Recibimos una variable en la llamada que será la misma que utilizaremos para
--mostrar el resultado
CREATE OR REPLACE PROCEDURE SUMA_IMPARES(numero IN OUT NUMBER)
AS 
--Declaramos las variables necesarias, asignamos a aux un valor inicial de 1
--para que sea el que controle cuándo salir del bucle y también el que represente
--los números impares y asignamos a original_numero el número que nos ha venido
--en la llamada
aux NUMBER := 1;
original_numero NUMBER := numero;
BEGIN 
--Asignamos a número el valor 0 para que sea la variable en la que sumemos
    numero := 0;
    WHILE aux <= original_numero  LOOP
        numero := numero + aux;
--Sumamos 2 a aux en cada iteración para obtener los números impares
        aux := aux + 2;
    END LOOP;
END; 
/

-- 2. NUMERO MAYOR
--Recibiremos en la llamada los 3 números que compararemos
CREATE OR REPLACE FUNCTION NUMERO_MAYOR (primero NUMBER, segundo NUMBER, tercero NUMBER)
RETURN NUMBER
IS
--Declaramos la variable que vamos a retornar y la de excepción
    final NUMBER;
    invalido EXCEPTION;
BEGIN
--Comprobamos si algún número es igual que el otro
    IF primero = segundo OR segundo = tercero THEN
--Si algún número está repetido lanzamos el error
    RAISE invalido;
    END IF;
--Vamos asignando a final el número que sea mayor
    IF primero > segundo THEN
    final := primero;
    ELSIF segundo > primero THEN
    final := segundo;
    END IF;
    IF tercero > final THEN
    final := tercero;
    END IF;
--Retornamos el número mayor guardado en final
    RETURN(final);
EXCEPTION
--Si ocurre la excepción, se muestra lo siguiente por consola
    WHEN invalido THEN
    DBMS_OUTPUT.PUT_LINE ('No se pueden repetir números en la secuencia' );
    RETURN 0;
END;
/

---------------------------------------------------------------
-- 4)	PROCEDIMIENTOS Y FUNCIONES COMPLEJAS ------------------ 
---------------------------------------------------------------

-- 1. DATOS DE EMPLEADO Y SU IRPF
--Recibimos en la llamada una serie de variables donde devolveremos los valores
--al finalizar el procedimiento y el id
CREATE OR REPLACE PROCEDURE IRPF_EMPLEADO(id IN OUT NUMBER, nombre IN OUT VARCHAR,
apellidos IN OUT VARCHAR, salario_anual IN OUT NUMBER, tramo_irpf IN OUT NUMBER,
irpf_porcentaje_limpio IN OUT NUMBER)
AS
    porcentaje NUMBER;
BEGIN
--Hacemos una consulta con el id para obtener los valores necesarios
    SELECT nombre, apellidos, salario
    INTO nombre, apellidos, salario_anual
    FROM EMPLEADOS_PAC
    WHERE id_empleado = id;
--Hacemos una consulta para obtener el tramo de IRPF y el porcentaje usando el
--salario anual
    SELECT tramo_irpf, porcentaje INTO tramo_irpf, porcentaje
    FROM IRPF_PAC
    WHERE valor_bajo < salario_anual AND valor_alto > salario_anual;
--Multiplicamos por 100 el porcentaje para obtener el número entero
    irpf_porcentaje_limpio := porcentaje  * 100;
    EXCEPTION
--En caso de que no se encuentren datos o haya muchas filas, nos devolverá este error
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE ('El número de empleado no existe en la tabla' );
END;
/

-- 2. NUMERO DE EMPLEADOS POR TRAMO DE IRPF
--Recibimos en la llamada el número de tramo
CREATE OR REPLACE FUNCTION EMPLEADOS_TRAMOS_IRPF (tramo NUMBER)
RETURN NUMBER
IS
--Declaramos las variables para guardar el valor bajo y alto de los tramos
--y el valor que retornaremos
    valor_bajo NUMBER(10, 2);
    valor_alto NUMBER(10, 2);
    final NUMBER;
BEGIN
--Realizamos una consulta para obtener el valor alto y bajo de los tramos de IRPF
    SELECT valor_bajo, valor_alto INTO valor_bajo, valor_alto
    FROM IRPF_PAC
    WHERE TRAMO_IRPF = tramo;
--Hacemos una consulta para obtener el número de empleados que se encuentran en
--dicho tramo y lo guardamos en la variable final
    SELECT COUNT(*) INTO final
    FROM EMPLEADOS_PAC
    WHERE salario >= valor_bajo AND salario <= valor_alto;
--Retornamos la variable final
    RETURN (final);
END;
/

---------------------------------------------------------------
-- 5)	GESTIÓN DE TRIGGERS ----------------------------------- 
---------------------------------------------------------------

-- 1. COMPENSACIÓN SALARIO POR CAMBIO TRAMO
--Creamos un trigger antes de que se modifique el salario de la tabla EMPLEADOS_PAC
CREATE OR REPLACE TRIGGER COMPENSA_TRAMO_IRPF BEFORE UPDATE
OF SALARIO ON EMPLEADOS_PAC FOR EACH ROW
DECLARE
--Declaramos dos variables para guardar el tramo anterior de IRPF y el nuevo
    tramo_anterior NUMBER;
    tramo_nuevo NUMBER;
BEGIN
--Realizamos un consulta para obtener el tramo anterior utilizando :old
    SELECT TRAMO_IRPF INTO tramo_anterior
    FROM IRPF_PAC
    WHERE :old.salario >= valor_bajo AND :old.salario <= valor_alto;
--Hacemos una consulta para obtener el nuevo tramo con :new
    SELECT TRAMO_IRPF INTO tramo_nuevo
    FROM IRPF_PAC
    WHERE :new.salario >= valor_bajo AND :new.salario <= valor_alto;
--Comprobamos si ambos tramos son el mismo y, en caso contrario, añadiremos 1000 al salario
    IF tramo_anterior != tramo_nuevo
    THEN :new.salario := :new.salario + 1000;
    END IF;
END;
/

-- 2. HISTORICO DE CAMBIOS DE SALARIO
CREATE TABLE AUDITA_SALARIOS (
    id_emp NUMBER(2),
    salario_antiguo NUMBER(10,2),
    salario_nuevo NUMBER(10,2),
    fecha DATE,
    hora VARCHAR2(10),
    username VARCHAR2(10)
);
--Creamos un trigger después de que se haya modificado el salario en la tabla
--EMPLEADOS_PAC, así si se dispara el trigger COMPENSA_TRAMO_IRPF, nos basaremos en el salario
--ya modificado tras ese trigger
CREATE OR REPLACE TRIGGER MODIFICACIONES_SALARIOS AFTER UPDATE
OF SALARIO ON EMPLEADOS_PAC FOR EACH ROW
DECLARE
--Declaramos las variables donde guardaremos los valores
    fecha DATE;
    hora VARCHAR2(10);
    username VARCHAR2(10);
BEGIN
--Sacamos el usuario de DUAL
    SELECT user INTO username FROM DUAL;
--Obtenemos la hora de DUAL
    SELECT to_char(sysdate, 'HH24:MI:ss') INTO hora FROM DUAL;
--Obtenemos la fecha de DUAL
    SELECT CURRENT_DATE INTO fecha FROM DUAL;
--Insertamos todos los datos
    INSERT INTO AUDITA_SALARIOS VALUES (:old.ID_EMPLEADO, :old.salario, :new.salario, fecha, hora, username);
END;
/

---------------------------------------------------------------
-- 6)   BLOQUES ANÓNIMOS PARA PRUEBAS DE CÓDIGO --------------- 
---------------------------------------------------------------

-- 1.	COMPROBACIÓN REGISTROS DE TABLAS
EXECUTE dbms_output.put_line('-- 1.	COMPROBACIÓN REGISTROS DE TABLAS');
--Realizamos dos consultas para comprobar los datos
SELECT * FROM ALUMNOS_PAC;
SELECT * FROM ASIGNATURAS_PAC;

-- 2.	COMPROBACIÓN DEL PROCEDIMIENTO “SUMA_IMPARES”
EXECUTE dbms_output.put_line('-- 2.	COMPROBACIÓN DEL PROCEDIMIENTO “SUMA_IMPARES”');
DECLARE
--Declaramos una variable número
    i NUMBER:= 6;
BEGIN
--Llamamos al procedimiento que guardará en i el resultado y lo mostramos
    SUMA_IMPARES(i);
    DBMS_OUTPUT.PUT_LINE('El resultado de sumar los impares hasta 6 es: ' || i);
END;
/

-- 3.	COMPROBACIÓN DE LA FUNCION “NUMERO_MAYOR”
EXECUTE dbms_output.put_line('-- 3.	COMPROBACIÓN DE LA FUNCION “NUMERO_MAYOR”');
BEGIN
--Llamamos a la función dentro de dbms_output.put_line para que la función
--nos devuelve el valor
    dbms_output.put_line('El mayor entre (23, 37, 32) es: ' || NUMERO_MAYOR (23, 37, 32));
END;
/

-- 4.	COMPROBACIÓN DEL PROCEDIMIENTO “IRPF_EMPLEADO”
EXECUTE dbms_output.put_line('-- 4.	COMPROBACIÓN DEL PROCEDIMIENTO “IRPF_EMPLEADO”');
DECLARE
--Declaramos las variables con las que llamaremos al procedimiento y donde se
--guardarán los valores
    i NUMBER:= 1;
    nombre VARCHAR(20);
    apellidos VARCHAR(30);
    salario_anual NUMBER(10, 2);
    tramo_irpf NUMBER(2);
    irpf_porcentaje_limpio NUMBER(2);
BEGIN
--Llamamos a la función con esos valores
    IRPF_EMPLEADO(i, nombre, apellidos, salario_anual, tramo_irpf, irpf_porcentaje_limpio);
--Imprimimos por pantalla la frase con  las variables
    DBMS_OUTPUT.PUT_LINE (nombre || ' ' || apellidos|| ', con salario de ' 
    || salario_anual || '€ en tramo ' || tramo_irpf  || ', con un IRPF de ' 
    || irpf_porcentaje_limpio || '%');
END;
/

-- 5.	COMPROBACIÓN DE LA FUNCION “EMPLEADOS_TRAMOS_IRPF”
EXECUTE dbms_output.put_line('-- 5.	COMPROBACIÓN DE LA FUNCION “EMPLEADOS_TRAMOS_IRPF”');
DECLARE
--Declaramos el número de tramo que pasaremos a la función
    i NUMBER:= 5;
BEGIN
--Imprimimos por la pantalla el resultado de la función
    DBMS_OUTPUT.PUT_LINE('En el tramo ' || i || ' de IRPF, tenemos a ' || EMPLEADOS_TRAMOS_IRPF (5) 
    || ' empleados');
END;
/

-- 6.	COMPROBACIÓN DE LOS TRIGGERS
EXECUTE dbms_output.put_line('-- 6.	COMPROBACIÓN DE LOS TRIGGERS');
DECLARE
--Declaramos las variables necesarias y les indicamos que deben ser del mismo
--tipo que las de AUDITA_SALARIOS
    id NUMBER(2);
    salario_insertado NUMBER(10,2);
    salario_antiguo AUDITA_SALARIOS.salario_antiguo%TYPE;
    salario_nuevo AUDITA_SALARIOS.salario_nuevo%TYPE;
    fecha AUDITA_SALARIOS.fecha%TYPE;
    hora AUDITA_SALARIOS.hora%TYPE;
    nombre VARCHAR2(10);
BEGIN
--Pedimos el número de id al usuario
    id := &id;
--Pedimos el salario al usuario
    salario_insertado := &salario_insertado;
--Obtenemos los datos del empleado con el id indicado
    SELECT  nombre INTO nombre FROM EMPLEADOS_PAC WHERE ID_EMPLEADO = id;
--Actualizamos el salario del empleado del id que se nos indicó
    UPDATE EMPLEADOS_PAC SET salario = salario_insertado WHERE ID_EMPLEADO = id;
--Realizamos una consulta para obtener los datos de la tabla AUDITA_SALARIOS
    SELECT salario_antiguo, salario_nuevo, fecha, hora INTO salario_antiguo, salario_nuevo, fecha, hora
    FROM AUDITA_SALARIOS WHERE id_emp = id;
--Mostramos por pantalla el resultado
    DBMS_OUTPUT.PUT_LINE('El salario del empleado ' ||nombre|| ' se ha modificado el día ' || fecha || ' ' || hora || 
    ', antes era de ' || salario_antiguo ||' € y ahora es de ' || salario_nuevo ||' €');
    EXCEPTION
--En caso de no encontrar datos o demasiadas filas, se lanzará la excepción
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE ('El número de empleado no existe en la tabla' );
END;
/