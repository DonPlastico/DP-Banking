<p align="center">
<h1 align="center">Sistema Bancario Avanzado para FiveM (QBCore)</h1>

<img width="960" height="auto" align="center" alt="DP-Banking Logo" src="Images (Can Remove it if u want)/Miniaturas YT.png" />

</p>

<div align="center">

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Script-important)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/QBCore-Framework-success)](<[https://qbcore-framework.github.io/qb-docs/](https://github.com/qbcore-framework)>)

</div>

<h2 align="center"> 📝 Descripción General</h2>
DP-Banking es un sistema bancario avanzado diseñado para servidores de FiveM que utilizan el framework QBCore. Este script proporciona a los jugadores una manera completa de gestionar sus finanzas a través de una interfaz NUI, con múltiples opciones de acceso y un control exhaustivo sobre sus transacciones.

<details>
<summary><h2 align="center">Características del Script</h2></summary>

- **Múltiples Puntos de Interacción:** Cajeros automáticos y sucursales bancarias en todo el mapa para un acceso conveniente. Puedes configurarlos fácilmente en config.lua.<br><br>
- **Gestión Completa de Cuentas:** Los jugadores pueden gestionar sus cuentas personales, transferir dinero, y ver estados de cuenta detallados.<br><br>
- **Cuentas de Jobs/Gangs:** Creación y gestión automática de cuentas bancarias para facciones y bandas, con acceso exclusivo para los jefes.<br><br>
- **Cuentas Compartidas:** Posibilidad de crear cuentas bancarias compartidas con otros jugadores.<br><br>
- **Integración de Tarjetas:** Un sistema de tarjetas bancarias que añade una capa extra de realismo al acceso a los cajeros automáticos.<br><br>

</details>
<br><br>
<h2 align="center"> 🚀 Documentación para Desarrolladores</h2>
El script incluye varias funciones exportadas del lado del servidor que pueden ser llamadas desde otros recursos para interactuar con el sistema bancario.

<details>
<summary><h2 align="center">CreatePlayerAccount</h2></summary>
Crea una nueva cuenta compartida para un jugador y regresa si fue exitosa o no.<br>

exports['DP-Banking']:CreatePlayerAccount(playerId, accountName, accountBalance, accountUsers)<br>

- playerId: number<br>
- accountName: string<br>
- accountBalance: number<br>
- accountUsers: table<br>
- returns: boolean<br>

Ejemplo:<br>
RegisterCommand('createPlayerAccount', function(source)<br>
local playerId = source<br>
local accountName = 'Mi cuenta compartida'<br>
local accountBalance = 5000<br>
local accountUsers = {'LLL11111', 'LLL11112'} -- Lista de citizenid<br>
exports['DP-Banking']:CreatePlayerAccount(playerId, accountName, accountBalance, json.encode(accountUsers))<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">CreateJobAccount</h2></summary>
Crea una nueva cuenta de tipo de job, esto se hace automáticamente, por lo que no debería ser necesario.<br>

exports['DP-Banking']:CreateJobAccount(accountName, accountBalance)<br>

- accountName: string<br>
- accountBalance: number<br>

Ejemplo:<br>
RegisterCommand('createJobAccount', function()<br>
local accountName = 'police'<br>
local accountBalance = 10000<br>
exports['DP-Banking']:CreateJobAccount(accountName, accountBalance)<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">CreateGangAccount</h2></summary>
Crea una nueva cuenta de tipo gang, esto se hace automáticamente por lo que no debería ser necesario.<br>

exports['DP-Banking']:CreateGangAccount(accountName, accountBalance)<br>

- accountName: string<br>
- accountBalance: number<br>

Ejemplo:<br>
RegisterCommand('createGangAccount', function()<br>
local accountName = 'ballas'<br>
local accountBalance = 10000<br>
exports['DP-Banking']:CreateGangAccount(accountName, accountBalance)<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">AddMoney</h2></summary>
Agrega dinero a una cuenta por nombre y regresa donde fue exitoso o no.<br>

exports['DP-Banking']:AddMoney(accountName, amount, reason)<br>

- accountName: string<br>
- amount: number<br>
- reason: string<br>
- returns: boolean<br>

Ejemplo:<br>
RegisterCommand('addMoney', function()<br>
local accountName = 'police'<br>
local amount = 10000<br>
exports['DP-Banking']:AddMoney(accountName, amount, 'Ejemplo')<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">RemoveMoney</h2></summary>
Retira dinero de una cuenta por nombre y regresa donde fue exitoso o no.<br>

exports['DP-Banking']:RemoveMoney(accountName, amount, reason)<br>

- accountName: string<br>
- amount: number<br>
- reason: string<br>
- returns: boolean<br>

Ejemplo:
RegisterCommand('removeMoney', function()<br>
local accountName = 'police'<br>
local amount = 10000<br>
exports['DP-Banking']:RemoveMoney(accountName, amount, 'Ejemplo')<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">GetAccount</h2></summary>
Devuelve toda la información de la cuenta especificada por nombre.<br>

exports['DP-Banking']:GetAccount(accountName)<br>

- accountName: string<br>
- returns: table | nil<br>

Ejemplo:<br>
RegisterCommand('getAccount', function()<br>
local accountName = 'police'<br>
local accountInfo = exports['DP-Banking']:GetAccount(accountName)<br>
if not accountInfo then print('Cuenta '..accountName..' no existe') return end<br>
for \_, info in pairs(accountInfo) do<br>
print('Nombre de cuenta: '..info.account_name)<br>
print('Saldo de cuenta: '..info.account_balance)<br>
print('Tipo de cuenta: '..info.account_type)<br>
end<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">GetAccountBalance</h2></summary>
Devuelve solo el saldo de la cuenta especificada por nombre.<br>

exports['DP-Banking']:GetAccountBalance(accountName)<br>

- accountName: string<br>
- returns: number<br>

Ejemplo:<br>
RegisterCommand('getBalance', function()<br>
local accountName = 'police'<br>
local balance = exports['DP-Banking']:GetAccountBalance(accountName)<br>
print('Cuenta: '..accountName..' Balance: '..balance)<br>
end, true)<br>

</details>
<details>
<summary><h2 align="center">CreateBankStatement</h2></summary>
Esto creará un estado de cuenta para una cuenta específica y regresará si fue exitoso o no.<br>

exports['DP-Banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)<br>

- playerId: number<br>
- account: string<br>
- amount: number<br>
- reason: string<br>
- statementType: string<br>
- accountType: string<br>
- returns: boolean<br>

Ejemplo:<br>
RegisterCommand('createBankStatement', function(source)<br>
local playerId = source<br>
local account = 'Mi cuenta compartida'<br>
local amount = 5000<br>
local reason = 'Dinero retirado'<br>
local statementType = 'withdraw' -- 'deposit', 'withdraw'<br>
local accountType = 'shared' -- 'player', 'shared', 'job', 'gang'<br>
local statementCreated = exports['DP-Banking']:CreateBankStatement(playerId, account, amount, reason, statementType, accountType)<br>
if statementCreated then print('Declaración creada') return end<br>
print('Error al crear la declaración')<br>
end, true)<br>

</details>
<br><br>
<h2 align="center"> 🚀 Instalación</h2>

<details>
<summary><h2 align="center">Requisitos previos</h2></summary>
- Servidor FiveM con QBCORE instalado.<br>
- MySQL configurado. (oxmysql)<br>
- PolyZone<br>

</details>
<details>
<summary><h2 align="center">Pasos de instalación</h2></summary>
1. **Descargar el script** desde el repositorio oficial.<br>
2. **Colocar la carpeta** en tu servidor con el nombre exacto `DP-Banking`.<br>
   - ⚠️ El nombre debe ser exactamente este para evitar problemas.<br>
3. **Configuración de la Base de Datos**.<br>
Abre el archivo Insert.sql.<br>
Copia y pega el contenido en tu base de datos MySQL y ejecútalo.
(Asegúrate de que tu servidor tenga acceso a la base de datos configurada para oxmysql.).<br>

</details>
<br><br>
<h2 align="center"> ⚙️ Dependencias</h2>
El script requiere las siguientes dependencias (deben estar instaladas y configuradas):
<details>
<summary><h2 align="center"> 📦 Requisitos del Sistema</h2></summary>

| Recurso                                                                                           | Descripción                                                                                         | Enlace                                                   |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| <img src="https://placehold.co/20x20/555555/FFFFFF?text=QB" alt="qb-core"> qb-core                | Framework principal                                                                                 | [🔗 GitHub](https://github.com/qbcore-framework/qb-core) |
| <img src="https://placehold.co/20x20/555555/FFFFFF?text=DP" alt="PD-TextUI"> PD-TextUI (optional) | Text UI avanzado                                                                                    | [🔗 GitHub]()                                            |
| <img src="https://placehold.co/20x20/555555/FFFFFF?text=QB" alt="DP-Menu"> DP-Menu                | Sistema de menús para QBCore Framework                                                              | [🔗 GitHub](https://github.com/qbcore-framework/DP-Menu) |
| <img src="https://placehold.co/20x20/555555/FFFFFF?text=PZ" alt="PolyZone"> PolyZone              | Script para definir zonas de diferentes formas y probar si un punto está dentro o fuera de la zona. | [🔗 GitHub](https://github.com/mkafrin/PolyZone)         |
| <img src="https://placehold.co/20x20/555555/FFFFFF?text=OX" alt="oxmysql"> oxmysql                | Recurso MySQL para FXServer.                                                                        | [🔗 GitHub](https://github.com/overextended/oxmysql)     |

</details>
<br><br>
<h2 align="center"> 📂 Estructura de Archivos</h2>

<details>
<summary><h2 align="center"> 🖥️ Mostrar estructura completa y descripción</h2></summary>

DP-PetsShop/<br>
├── 📁 html/<br>
│ ├── 🌐 index.html<br>
│ ├── 📄 script.js<br>
│ └── 🎨 style.css<br>
├── 📁 locales/<br>
│ ├── 🔵 en.lua<br>
│ ├── 🔵 es.lua<br>
│ ├── 🔵 it.lua<br>
│ └── 🔵 nl.lua<br>
├── 🗄️ Insert.sql<br>
├── 📜 LICENSE<br>
├── 📖 README.md<br>
├── 🔵 client.lua<br>
├── 🔵 config.lua<br>
├── 🔵 fxmanifest.lua<br>
└── 🔵 server.lua<br>

</div>

> ** 💡 Datos Técnicos:** La estructura está optimizada para consumo mínimo de recursos (0.01ms) y máxima compatibilidad con QBCore.

</details>
<br><br>
<h2 align="center">🛠️ Configuración</h2>
El archivo config.lua te permite personalizar el script según tus necesidades.

<details>
<summary><h2 align="center">⚙️ Mostrar configuración</h2></summary>

<h3>config.lua</h3>
<img width="600" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/config.png" />

| Archivo        | Función Principal                                                                                            |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| **config.lua** | Define las configuraciones principales del script, como el control del DP-TextUI, modelos, localizaciones... |

</details>
<br><br>
<h2 align="center"> 🖼️ Vistas Previas</h2>
Aquí tienes una lista de las vistas previas de tu script.

<details>
<p align="center">
<summary><h2 align="center">Interfaz del Banco</h2></summary>

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 1.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 2.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 3.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 4.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 5.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 6.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 7.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Banco 8.png" />

</p>
</details>
<details>
<p align="center">
<summary><h2 align="center">Interfaz sacar Tarjeta</h2></summary>

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/tarjeta 1.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/tarjeta 2.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/tarjeta 3.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/tarjeta 4.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/tarjeta 5.png" />

</p>
</details>
<details>
<p align="center">
<summary><h2 align="center">Interfaz eliminar Tarjetas robadas</h2></summary>

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/robao 1.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/robao 2.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/robao 4.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/robao 3.png" />

</p>
</details>
<details>
<p align="center">
<summary><h2 align="center">Interfaz del Cajero</h2></summary>

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/cajero 1.png" />

<img width="400" height="auto" alt="image" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/cajero 2.png" />

</p>
</details>
<details>
<p align="center">
<summary><h2 align="center">Video Demostrativo</h2></summary>

<a href="https://youtu.be/Nm9mC5QZ57w">
<img width="959" height="auto" alt="Video Demostrativo" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);" src="Images (Can Remove it if u want)/Miniaturas YT.png" />
</a>

</p>
</details>
<br><br>
<h2 align="center"> 🔮 Posibles Mejoras Futuras</h2>
El script DP-Banking es un sistema robusto, pero siempre hay espacio para mejoras y nuevas funcionalidades para enriquecer la experiencia de juego.

<details>
<summary><h2 align="center">🚧 En desarrollo</h2></summary>

| IDEA                              | EXPLICACIÓN                                                                                                                                                                                                    |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sistema de inversión**          | Implementar un sistema de bolsa o mercado de valores donde los jugadores puedan comprar y vender acciones de empresas del juego. El valor de las acciones podría fluctuar según las acciones de los jugadores. |
| **Préstamos entre jugadores**     | Habilitar que los jugadores puedan prestarse dinero entre sí a través del banco, con un contrato digital que asegure el cumplimiento de los pagos.                                                             |
| **Integración con criptomonedas** | Añadir una opción para que los jugadores compren y vendan criptomonedas en el juego, como con la app de criptomonedas del qb-phone... con un mercado volátil que cambie los precios con el tiempo.             |
| **Impuestos y pagos automáticos** | Crear un sistema donde los jugadores tengan que pagar impuestos periódicamente o puedan configurar pagos automáticos para sus facturas de casa, coche, etc.                                                    |

</details>

Autor: DP-Scripts<br>
Versión: 1.0.0
