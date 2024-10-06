local Translations = {
    success = {
        withdraw = 'Has retirado exitosamente',
        deposit = 'Has depositado exitosamente',
        transfer = 'Transferencia exitosa',
        account = 'Cuenta creada',
        rename = 'Cuenta renombrada',
        delete = 'Cuenta eliminada',
        userAdd = 'Persona añadida',
        userRemove = 'Persona eliminada',
        card = 'Tarjeta creada',
        give = 'Has dado $%s',
        receive = 'Has recivido $%s',
    },
    error = {
        error = 'Ha ocurrido un error',
        access = 'No estas autorizado',
        account = 'Cuenta no encontrada',
        accounts = 'Tienes el maximo de cuentas',
        user = 'Persona ya añadida',
        noUser = 'No se encuentra la persona',
        money = 'No tienes suficiente dinero',
        pin = 'PIN erroneo',
        card = 'No tienes la tarjeta del banco',
        amount = 'Cantidad invalida',
        toofar = 'Estás demasiado lejos',
    },
    progress = {
        atm = 'Accediendo al cajero',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
