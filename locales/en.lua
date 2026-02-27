local Translations = {
    success = {
        withdraw = 'Has retirado exitosamente',
        deposit = 'Has depositado exitosamente',
        transfer = 'Transferencia exitosa',
        account = 'Cuenta creada',
        rename = 'Cuenta renombrada',
        delete = 'Cuenta eliminada',
        userAdd = 'Usuario añadido',
        userRemove = 'Usuario eliminado',
        card = 'Tarjeta creada',
        give = '$%s efectivo dado',
        receive = '$%s efectivo recibido'
    },
    error = {
        error = 'Se produjo un error',
        access = 'No autorizado',
        account = 'Cuenta no encontrada',
        accounts = 'Número máximo de cuentas creadas',
        user = 'Usuario ya agregado',
        noUser = 'Usuario no encontrado',
        money = 'No tienes suficiente dinero',
        pin = 'PIN no válido',
        card = 'No se encontró ninguna tarjeta bancaria',
        amount = 'Cantidad no válida',
        toofar = 'Estás demasiado lejos'
    },
    progress = {
        atm = 'Accediendo al cajero automático'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
