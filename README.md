# IASC Notes

## TP Grupal - IASC 2C2022
### Grupo 1

### Enunciado
https://docs.google.com/document/d/1Oy7tNtCV3-BzthtaMwHOMLoghpMZj5JcvUuSoc4xyr0

El link a la documentacion general de la aplicacion la pueden encontrar en el siguiente link:

https://docs.google.com/document/d/1J1KQsm9-BTqRnmWivQgew6jYs8_CGe8PI8u6AOBXygM/edit

## App

Para poder correr la aplicacion localmente (sin doker), luego de clonar el repositorio, se debe parar sobre la carpeta clonada y ejecutar el siguiente comando para instalar las dependencias:

`mix deps.get`

Luego de ello, podra correr los nodos que crea convenientes con el siguiente comando:

iex --sname node1 --cookie cookie -S mix phx.server

Indicando en el parametro --sname el nombre que desea asignarle a cada nodo y asignandole puertos distintos a cada uno. Para esto, se debe cambiar el puerto en el archivo '/config/dev.xes' o cambiando la variable de entoro 'PUERTO'.

Una vez que tenga los nodos que crea necesario (con 2 nodos es suficiente para probar los escenarios), podra continuar con la puesta en marcha del frontend, para ello puede seguir con las instrucciones que se encuentran en la carpeta /frontend/readme.md o tambien en el siguiente repositorio:

https://github.com/matiasfarran/IASCFront

### Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
