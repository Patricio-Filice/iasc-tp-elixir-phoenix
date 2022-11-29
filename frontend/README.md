# IASCFront
Front para el TP de arquitecturas de SW concurrentes.

Este front esta realizado en react y dministra "to do list".

Para correr este front, primero se deben correr los nodos que se quieran utilizar de backend, estos se pueden encontrar en la siguiente url:
https://github.com/Patricio-Filice/iasc-tp-elixir-phoenix

Se recomienda que se corran minimo 2 nodos y estos operen en los puertos 4000 y 4001 para que coincida con la configuracion del .env utilizado. En caso de utilizar 1 solo nodo, se debe cambiar el .env para incluir el mismo puerto en la variable  REACT_APP_API_BACKEND_FROM_PORT y REACT_APP_API_BACKEND_TO_PORT.

Luego de tener los nodos corriendo se debe installar las dependencias del proyecto. Para realizar ese paso pararse en la carpeta principal y ejecutar el siguiente comando:

npm install --legacy-peer-deps

Luego de instalar las dependencias se debe correr la aplicacion con la configuracion que se encuentra en el archivo .env, utilizando el siguiente comando:

npm start .env

