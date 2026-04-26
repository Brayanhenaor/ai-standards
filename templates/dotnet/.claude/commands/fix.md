# Debugging sistemático

Tengo el siguiente problema: $ARGUMENTS

Proceso:
1. Lee el error completo o describe el comportamiento inesperado
2. Identifica los archivos más probablemente involucrados
3. Formula una hipótesis antes de tocar código
4. Propón la solución mínima que resuelve el problema
5. Indica cómo verificar que el fix funciona (test, endpoint, log esperado)

No hagas ningún cambio hasta que yo confirme la hipótesis.

Si el error es una excepción de .NET, analiza el stack trace completo antes de proponer nada.
