const bankingApp = Vue.createApp({
    data() {
        return {
            isBankOpen: false,
            isATMOpen: false,
            showPinPrompt: false,
            notification: null,
            isLoading: false,
            loadingText: "ACCEDIENDO AL BANCO...",
            activeView: "home",
            accounts: [
                { name: "Personal", type: "Personal", balance: 0, id: 100023456789 },
                { name: "savings", type: "savings", balance: 0, id: 100023456788 },
            ],
            statements: {},
            selectedAccountStatement: "Personal",
            playerName: "",
            accountNumber: "",
            playerCash: 0,
            selectedMoneyAccount: null,
            selectedMoneyAmount: 0,
            moneyReason: "",
            transferType: "internal",
            internalFromAccount: null,
            internalToAccount: null,
            internalTransferAmount: 0,
            externalAccountNumber: "",
            externalFromAccount: null,
            externalTransferAmount: 0,
            transferReason: "",
            debitPin: "",
            enteredPin: "",
            acceptablePins: [],
            tempBankData: null,
            createAccountName: "",
            createAccountAmount: 0,
            editAccount: null,
            editAccountName: "",
            manageAccountName: null,
            manageUserName: "",
            filteredUsers: [],
            showUsersDropdown: false,
            transferAmount: 0,
            selectedFromAccount: null,
            activeAccountTab: 'shared',
            selectedEditAccount: null,
            selectedUserAccount: null,
            userSearchQuery: '',
            userSearchResults: [],
            showCreateAccountModal: false,
            showDistributeConfirmationModal: false,
            newAccountName: '',
            newAccountAmount: 0,
            showEditAccountModal: false,
            showDeleteConfirmation: false,
            accountToDelete: null,
            accountUsers: [],
            loadingUsers: false
        };
    },
    computed: {
        sharedAccounts() {
            return this.accounts.filter(account => account.type === 'shared');
        },
        canCreateAccount() {
            return this.newAccountName.trim() !== '' &&
                this.newAccountAmount > 0 &&
                this.accounts.length < 5;
        },
        accountStatements() {
            if (this.selectedAccountStatement && this.statements[this.selectedAccountStatement]) {
                return this.statements[this.selectedAccountStatement];
            }
            return [];
        },
    },
    watch: {
        selectedUserAccount: {
            async handler(newVal) {
                if (newVal) {
                    await this.loadAccountUsers(newVal);
                }
            },
            immediate: true
        },
        activeView(newVal) {
            if (newVal === 'withdraw' && this.accounts.length > 0 && !this.selectedMoneyAccount) {
                this.selectedMoneyAccount = this.accounts[0]; // Selecciona la primera cuenta por defecto
            }
        },
        "manageAccountName.users": function () {
            this.filterUsers();
        },
    },
    methods: {
        distributeCashToAllAccounts() {
            if (this.playerCash <= 0 || this.accounts.length === 0) {
                this.addNotification("No tienes efectivo o cuentas disponibles", "error");
                return;
            }

            const amountPerAccount = Math.floor(this.playerCash / this.accounts.length);
            if (amountPerAccount <= 0) {
                this.addNotification("El efectivo no es suficiente para distribuir", "error");
                return;
            }

            // Muestra el modal de confirmación en lugar de usar confirm()
            this.showDistributeConfirmationModal = true;
        },
        confirmDistribution() {
            const amountPerAccount = Math.floor(this.playerCash / this.accounts.length);
            this.accounts.forEach(account => {
                this.selectedMoneyAccount = account;
                this.selectedMoneyAmount = amountPerAccount;
                this.moneyReason = "Distribución automática de efectivo";
                this.depositMoney();
            });
            this.addNotification(`Se distribuyeron $${this.formatCurrency(this.playerCash)} entre ${this.accounts.length} cuentas`, "success");
            this.showDistributeConfirmationModal = false; // Oculta el modal
        },
        cancelDistribution() {
            this.showDistributeConfirmationModal = false; // Oculta el modal sin hacer nada
        },
        async loadAccountUsers(account) {
            this.loadingUsers = true;
            try {
                const users = this.getAccountUsers(account);

                // Obtener información de cada usuario
                const usersData = await Promise.all(users.map(async citizenid => {
                    try {
                        const response = await axios.post("https://DP-Banking/getUserInfo", { citizenid });
                        return response.data;
                    } catch (error) {
                        console.error(`Error fetching user ${citizenid}:`, error);
                        return { name: "Usuario desconocido", citizenid };
                    }
                }));

                this.accountUsers = usersData;
            } catch (error) {
                console.error("Error loading account users:", error);
                this.accountUsers = [];
            } finally {
                this.loadingUsers = false;
            }
        },

        async removeUserFromAccount(citizenid) {
            if (!this.selectedUserAccount || !citizenid) return;

            try {
                const response = await axios.post("https://DP-Banking/removeUser", {
                    accountName: this.selectedUserAccount.name,
                    userName: citizenid
                });

                if (response.data.success) {
                    this.addNotification(response.data.message, "success");
                    await this.loadAccountUsers(this.selectedUserAccount);
                } else {
                    this.addNotification(response.data.message, "error");
                }
            } catch (error) {
                console.error("Error removing user:", error);
                this.addNotification("Error al eliminar usuario", "error");
            }
        },
        selectAccountToEdit(account) {
            this.editAccount = account;
            this.editAccountName = account.name;
            this.showEditAccountModal = true;
        },

        cancelEdit() {
            this.editAccount = null;
            this.editAccountName = "";
        },

        getAccountUsers(account) {
            try {
                // Obtener usuarios de la cuenta
                let users = JSON.parse(account.users || '[]');

                // Asegurarse de incluir al creador de la cuenta si existe
                if (account.citizenid && !users.includes(account.citizenid)) {
                    users.unshift(account.citizenid);
                }

                return users;
            } catch (e) {
                console.error("Error parsing users:", e);
                return [];
            }
        },
        async getUserInfo(citizenid) {
            try {
                const response = await axios.post("https://DP-Banking/getUserInfo", { citizenid });
                return response.data;
            } catch (error) {
                console.error("Error fetching user info:", error);
                return { name: "Usuario desconocido", citizenid };
            }
        },

        getUserInitials(citizenid) {
            // Esto es un ejemplo - deberías obtener el nombre real del usuario
            return citizenid.substring(0, 2).toUpperCase();
        },

        searchUsers() {
            if (this.userSearchQuery.length < 3) {
                this.userSearchResults = [];
                return;
            }

            // Aquí deberías hacer una llamada al servidor para buscar usuarios
            // Esto es solo un ejemplo
            this.userSearchResults = [
                { citizenid: 'ABC123', name: 'John Doe' },
                { citizenid: 'DEF456', name: 'Jane Smith' }
            ].filter(user =>
                user.name.toLowerCase().includes(this.userSearchQuery.toLowerCase()) ||
                user.citizenid.toLowerCase().includes(this.userSearchQuery.toLowerCase())
            );
        },

        openUserPermissions(userId) {
            // Implementar lógica para abrir modal de permisos
            this.addNotification('Funcionalidad de permisos en desarrollo', 'info');
        },

        confirmDeleteAccount(account) {
            this.accountToDelete = account;
            this.showDeleteConfirmation = true;
        },

        executeDeleteAccount() {
            if (!this.accountToDelete) return;

            axios.post("https://DP-Banking/deleteAccount", {
                accountName: this.accountToDelete.name
            }).then(response => {
                if (response.data.success) {
                    // Eliminar localmente
                    this.accounts = this.accounts.filter(acc => acc.name !== this.accountToDelete.name);
                    this.addNotification("Cuenta eliminada correctamente", "success");

                    // Resetear selección si era la cuenta actual
                    if (this.selectedAccountStatement === this.accountToDelete.name) {
                        this.selectedAccountStatement = this.accounts[0]?.name || '';
                    }
                } else {
                    this.addNotification(response.data.message || "Error al eliminar", "error");
                }
                this.showDeleteConfirmation = false;
                this.accountToDelete = null;
            }).catch(error => {
                console.error("Error deleting account:", error);
                this.addNotification("Error al eliminar la cuenta", "error");
                this.showDeleteConfirmation = false;
            });
        },
        cancelDelete() {
            this.showDeleteConfirmation = false;
            this.accountToDelete = null;
        },

        createNewAccount() {
            if (!this.canCreateAccount) return;

            axios.post("https://DP-Banking/openAccount", {
                accountName: this.newAccountName,
                amount: this.newAccountAmount
            }).then(response => {
                if (response.data.success) {
                    this.addNotification(response.data.message, "success");
                    this.showCreateAccountModal = false;
                    this.newAccountName = '';
                    this.newAccountAmount = 0;

                    // Actualizar lista de cuentas
                    this.accounts.push({
                        name: this.newAccountName,
                        type: "shared",
                        balance: this.newAccountAmount,
                        users: JSON.stringify([this.accountNumber])
                    });
                } else {
                    this.addNotification(response.data.message, "error");
                }
            }).catch(error => {
                console.error("Error creating account:", error);
                this.addNotification("Error al crear la cuenta", "error");
            });
        },
        handleTransfer() {
            if (!this.selectedFromAccount) {
                this.addNotification("Debes seleccionar una cuenta de origen", "error");
                return;
            }

            if (this.transferType === 'internal') {
                if (!this.internalToAccount) {
                    this.addNotification("Debes seleccionar una cuenta destino", "error");
                    return;
                }
                this.internalFromAccount = this.selectedFromAccount;
                this.internalTransferAmount = this.transferAmount;
                this.internalTransfer();
            } else {
                if (!this.externalAccountNumber) {
                    this.addNotification("Debes ingresar un número de cuenta destino", "error");
                    return;
                }
                this.externalFromAccount = this.selectedFromAccount;
                this.externalTransferAmount = this.transferAmount;
                this.externalTransfer();
            }
        },
        autoResizeTextarea(event) {
            const textarea = event.target;
            textarea.style.height = 'auto'; // Reset height
            textarea.style.height = textarea.scrollHeight + 'px'; // Ajusta al contenido
        },
        quickDeposit(amount) {
            const account = this.accounts.find(acc => acc.name === this.selectedAccountStatement);
            if (!account) return;

            this.selectedMoneyAccount = account;
            this.selectedMoneyAmount = amount;
            this.moneyReason = "Depósito rápido";
            this.depositMoney();
        },

        quickWithdraw(amount) {
            const account = this.accounts.find(acc => acc.name === this.selectedAccountStatement);
            if (!account) return;

            this.selectedMoneyAccount = account;
            this.selectedMoneyAmount = amount;
            this.moneyReason = "Retiro rápido";
            this.withdrawMoney();
        },
        openBank(bankData) {
            this.isLoading = true;
            this.loadingText = "ACCEDIENDO AL BANCO...";

            // Simular carga de 5 segundos
            setTimeout(() => {
                if (bankData.openAccountView) {
                    this.setActiveView('accountOptions');
                }
                const playerData = bankData.playerData;
                this.playerName = playerData.charinfo.firstname;
                this.accountNumber = playerData.citizenid;
                this.playerCash = playerData.money.cash;
                this.accounts = [];
                bankData.accounts.forEach((account) => {
                    this.accounts.push({
                        name: account.account_name,
                        type: account.account_type,
                        balance: account.account_balance,
                        users: account.users,
                        id: account.id,
                    });
                });
                this.statements = {};
                Object.keys(bankData.statements).forEach((accountKey) => {
                    this.statements[accountKey] = bankData.statements[accountKey].map((statement) => ({
                        id: statement.id,
                        date: statement.date,
                        reason: statement.reason,
                        amount: statement.amount,
                        type: statement.statement_type,
                        user: statement.citizenid,
                    }));
                });
                this.isBankOpen = true;
                this.isLoading = false;
            }, 1500);
        },
        openATM(bankData) {
            this.isLoading = true;
            this.loadingText = "ACCEDIENDO AL BANCO...";
            setTimeout(() => {
                const playerData = bankData.playerData;
                this.playerName = playerData.charinfo.firstname;
                this.accountNumber = playerData.citizenid;
                this.playerCash = playerData.money.cash;
                this.accounts = [];
                bankData.accounts.forEach((account) => {
                    this.accounts.push({
                        name: account.account_name,
                        type: account.account_type,
                        balance: account.account_balance,
                        users: account.users,
                        id: account.id,
                    });
                });
                this.isATMOpen = true;
                this.isLoading = false;
            }, 1500);
        },
        pinPrompt(enteredPin) {
            const bankData = this.tempBankData;
            this.acceptablePins = Array.from(bankData.pinNumbers);
            if (this.acceptablePins.includes(parseInt(enteredPin))) {
                this.showPinPrompt = false;
                this.openATM(bankData);
            }
        },
        withdrawMoney() {
            if (!this.selectedMoneyAccount || this.selectedMoneyAmount <= 0) {
                return;
            }
            axios
                .post("https://DP-Banking/withdraw", {
                    accountName: this.selectedMoneyAccount.name,
                    amount: this.selectedMoneyAmount,
                    reason: this.moneyReason,
                })
                .then((response) => {
                    if (response.data.success) {
                        const account = this.accounts.find((acc) => acc.name === this.selectedMoneyAccount.name);
                        if (account) {
                            account.balance -= this.selectedMoneyAmount;
                            this.playerCash += this.selectedMoneyAmount;
                            this.addStatement(this.accountNumber, this.selectedMoneyAccount.name, this.moneyReason,
                                this.selectedMoneyAmount, "withdraw", null, this.selectedMoneyAccount.name);
                            this.selectedMoneyAmount = 0;
                            this.moneyReason = "";
                            this.selectedMoneyAccount = null;
                        }
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        depositMoney() {
            if (!this.selectedMoneyAccount || this.selectedMoneyAmount <= 0) {
                return;
            }
            axios
                .post("https://DP-Banking/deposit", {
                    accountName: this.selectedMoneyAccount.name,
                    amount: this.selectedMoneyAmount,
                    reason: this.moneyReason,
                })
                .then((response) => {
                    if (response.data.success) {
                        const account = this.accounts.find((acc) => acc.name === this.selectedMoneyAccount.name);
                        if (account) {
                            account.balance += this.selectedMoneyAmount;
                            this.playerCash -= this.selectedMoneyAmount;
                            this.addStatement(this.accountNumber, this.selectedMoneyAccount.name, this.moneyReason,
                                this.selectedMoneyAmount, "deposit", this.selectedMoneyAccount.name, null);
                            this.selectedMoneyAmount = 0;
                            this.moneyReason = "";
                            this.selectedMoneyAccount = null;
                        }
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        internalTransfer() {
            if (!this.internalFromAccount || !this.internalToAccount || this.internalTransferAmount <= 0) {
                return;
            }
            axios
                .post("https://DP-Banking/internalTransfer", {
                    fromAccountName: this.internalFromAccount.name,
                    toAccountName: this.internalToAccount.name,
                    amount: this.internalTransferAmount,
                    reason: this.transferReason,
                })
                .then((response) => {
                    if (response.data.success) {
                        const fromAccount = this.accounts.find((acc) => acc.name === this.internalFromAccount.name);
                        if (fromAccount) {
                            fromAccount.balance -= this.internalTransferAmount;
                        }
                        const toAccount = this.accounts.find((acc) => acc.name === this.internalToAccount.name);
                        if (toAccount) {
                            toAccount.balance += this.internalTransferAmount;
                        }
                        this.addStatement(this.accountNumber, this.internalFromAccount.name, this.transferReason,
                            this.internalTransferAmount, "withdraw", this.internalToAccount.name, this.internalFromAccount.name);
                        this.addStatement(this.accountNumber, this.internalToAccount.name, this.transferReason,
                            this.internalTransferAmount, "deposit", this.internalToAccount.name, this.internalFromAccount.name);
                        this.internalTransferAmount = 0;
                        this.transferReason = "";
                        this.internalFromAccount = null;
                        this.internalToAccount = null;
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        externalTransfer() {
            if (!this.externalFromAccount || !this.externalAccountNumber || this.externalTransferAmount <= 0) {
                return;
            }
            axios
                .post("https://DP-Banking/externalTransfer", {
                    fromAccountName: this.externalFromAccount.name,
                    toAccountNumber: this.externalAccountNumber,
                    amount: this.externalTransferAmount,
                    reason: this.transferReason,
                })
                .then((response) => {
                    if (response.data.success) {
                        const fromAccount = this.accounts.find((acc) => acc.name === this.externalFromAccount.name);
                        if (fromAccount) {
                            fromAccount.balance -= this.externalTransferAmount;
                        }
                        this.addStatement(this.accountNumber, this.externalFromAccount.name, this.transferReason,
                            this.externalTransferAmount, "withdraw", this.externalAccountNumber, this.externalFromAccount.name);
                        this.externalTransferAmount = 0;
                        this.transferReason = "";
                        this.externalFromAccount = null;
                        this.externalAccountNumber = "";
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        orderDebitCard() {
            if (!this.debitPin) {
                return;
            }

            axios
                .post("https://DP-Banking/orderCard", {
                    pin: this.debitPin,
                })
                .then((response) => {
                    if (response.data.success) {
                        this.debitPin = "";
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        openAccount() {
            if (!this.createAccountName || this.createAccountAmount < 0) {
                return;
            }

            axios
                .post("https://DP-Banking/openAccount", {
                    accountName: this.createAccountName,
                    amount: this.createAccountAmount,
                })
                .then((response) => {
                    if (response.data.success) {
                        const PersonalAccount = this.accounts.find((acc) => acc.name === "Personal");
                        if (PersonalAccount) {
                            PersonalAccount.balance -= this.createAccountAmount;
                        }

                        // Crear el objeto de cuenta correctamente formateado
                        const newAccount = {
                            name: this.createAccountName,
                            type: "shared",
                            balance: this.createAccountAmount,
                            users: [this.accountNumber] // Usar el citizenid en lugar del nombre
                        };

                        this.accounts.push(newAccount);

                        // Actualizar statements
                        this.addStatement(this.accountNumber, "Personal",
                            "Initial deposit for " + this.createAccountName,
                            this.createAccountAmount, "withdraw");

                        this.addStatement(this.accountNumber, this.createAccountName,
                            "Initial deposit",
                            this.createAccountAmount, "deposit");

                        // Resetear valores
                        this.createAccountName = "";
                        this.createAccountAmount = 0;

                        this.addNotification(response.data.message, "success");
                    } else {
                        this.createAccountName = "";
                        this.createAccountAmount = 0;
                        this.addNotification(response.data.message, "error");
                    }
                })
                .catch((error) => {
                    console.error("Error creating account:", error);
                    this.addNotification("Error al crear la cuenta", "error");
                    this.createAccountName = "";
                    this.createAccountAmount = 0;
                });
        },
        renameAccount() {
            if (!this.editAccount || !this.editAccountName.trim()) {
                this.addNotification("Debes ingresar un nombre válido", "error");
                return;
            }

            if (this.editAccountName === this.editAccount.name) {
                this.addNotification("El nuevo nombre debe ser diferente al actual", "error");
                return;
            }

            axios.post("https://DP-Banking/renameAccount", {
                oldName: this.editAccount.name,
                newName: this.editAccountName
            }).then(response => {
                if (response.data.success) {
                    const account = this.accounts.find(acc => acc.name === this.editAccount.name);
                    if (account) {
                        account.name = this.editAccountName;
                        // Actualizar también la cuenta seleccionada si es la misma
                        if (this.selectedAccountStatement === this.editAccount.name) {
                            this.selectedAccountStatement = this.editAccountName;
                        }
                    }
                    this.addNotification(response.data.message, "success");
                    this.showEditAccountModal = false;
                } else {
                    this.addNotification(response.data.message || "Error al renombrar", "error");
                }
            }).catch(error => {
                console.error("Error renaming account:", error);
                this.addNotification("Error al renombrar la cuenta", "error");
            });
        },
        deleteAccount() {
            if (!this.accountToDelete) return;

            axios.post("https://DP-Banking/deleteAccount", {
                accountName: this.accountToDelete.name
            }).then(response => {
                if (response.data.success) {
                    this.accounts = this.accounts.filter(acc => acc.name !== this.accountToDelete.name);
                    this.addNotification("Cuenta eliminada correctamente", "success");

                    if (this.selectedAccountStatement === this.accountToDelete.name) {
                        this.selectedAccountStatement = this.accounts[0]?.name || '';
                    }
                } else {
                    this.addNotification(response.data.message || "Error al eliminar", "error");
                }
                this.showDeleteConfirmation = false;
            }).catch(error => {
                console.error("Error deleting account:", error);
                this.addNotification("Error al eliminar la cuenta", "error");
                this.showDeleteConfirmation = false;
            });
        },
        addUserToAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }
            axios
                .post("https://DP-Banking/addUser", {
                    accountName: this.manageAccountName.name,
                    userName: this.manageUserName,
                })
                .then((response) => {
                    if (response.data.success) {
                        let usersArray = JSON.parse(this.manageAccountName.users);
                        usersArray.push(this.manageUserName);
                        this.manageAccountName.users = JSON.stringify(usersArray);
                        this.manageUserName = "";
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        removeUserFromAccount() {
            if (!this.manageAccountName || !this.manageUserName) {
                return;
            }

            axios
                .post("https://DP-Banking/removeUser", {
                    accountName: this.manageAccountName.name,
                    userName: this.manageUserName,
                })
                .then((response) => {
                    if (response.data.success) {
                        let usersArray = JSON.parse(this.manageAccountName.users);
                        usersArray = usersArray.filter((user) => user !== this.manageUserName);
                        this.manageAccountName.users = JSON.stringify(usersArray);
                        this.manageUserName = "";
                        this.addNotification(response.data.message, "success");
                    } else {
                        this.addNotification(response.data.message, "error");
                    }
                });
        },
        addStatement(accountNumber, accountName, reason, amount, type, targetAccount = null, sourceAccount = null) {
            let newStatement = {
                date: Date.now(),
                user: accountNumber,
                reason: reason,
                amount: amount,
                type: type,
                targetAccount: targetAccount,
                sourceAccount: sourceAccount
            };

            if (!this.statements[accountName]) {
                this.statements[accountName] = [];
            }

            this.statements[accountName].push(newStatement);
        },
        addNotification(message, type) {
            // Si el mensaje es muy técnico (contiene "Duplicate entry"), mostramos uno más amigable
            if (typeof message === 'string' && message.includes('Duplicate entry')) {
                message = "Ya existe una cuenta con ese nombre. Por favor elige otro.";
            }

            this.notification = {
                message: message,
                type: type,
            };

            setTimeout(() => {
                this.notification = null;
            }, 5000); // Aumentamos el tiempo a 5 segundos para errores
        },
        appendNumber(number) {
            this.enteredPin += number.toString();
        },
        selectAccount(account) {
            this.selectedAccountStatement = account.name;
        },
        setTransferType(type) {
            this.transferType = type;
        },
        setActiveView(view) {
            this.activeView = view;
        },
        formatCurrency(amount) {
            return '$' + new Intl.NumberFormat('en-US').format(amount);
        },
        filterUsers() {
            if (!this.manageAccountName || typeof this.manageAccountName.users !== "string") {
                this.filteredUsers = [];
                return;
            }
            let usersArray;
            try {
                usersArray = JSON.parse(this.manageAccountName.users);
            } catch (e) {
                this.filteredUsers = [];
                return;
            }
            if (this.manageUserName === "") {
                this.filteredUsers = usersArray;
            } else {
                this.filteredUsers = usersArray.filter((user) => user.toLowerCase().includes(this.manageUserName.toLowerCase()));
            }
        },

        selectUser(user) {
            this.manageUserName = user.citizenid;
            this.userSearchQuery = user.name;
            this.userSearchResults = [];
        },
        hideDropdown() {
            setTimeout(() => {
                this.showUsersDropdown = false;
            }, 100);
        },
        formatDate(timestamp) {
            const date = new Date(parseInt(timestamp));
            const day = date.getDate().toString().padStart(2, "0");
            const month = (date.getMonth() + 1).toString().padStart(2, "0");
            const year = date.getFullYear().toString().slice(-2);
            const hours = date.getHours().toString().padStart(2, "0");
            const minutes = date.getMinutes().toString().padStart(2, "0");
            return `${day}/${month}/${year} ${hours}:${minutes}`;
        },
        balanceClass(statementType) {
            return statementType === "deposit" ? "positive-balance" : "negative-balance";
        },
        handleMessage(event) {
            const action = event.data.action;
            if (action === "openBank") {
                this.openBank(event.data);
            } else if (action === "openATM") {
                this.tempBankData = event.data;
                this.showPinPrompt = true;
            } else if (action === "setActiveView") {
                this.setActiveView(event.data.view);
            }
        },
        handleKeydown(event) {
            if (event.key === "Escape") {
                this.closeApplication();
            }
        },
        closeApplication() {
            // Mostrar pantalla de carga al cerrar
            this.isLoading = true;
            this.loadingText = "SALIENDO DEL BANCO...";

            // Simular un pequeño retraso para la animación de cierre
            setTimeout(() => {
                if (this.isBankOpen) {
                    this.isBankOpen = false;
                } else if (this.isATMOpen) {
                    this.isATMOpen = false;
                } else if (this.showPinPrompt) {
                    this.showPinPrompt = false;
                    this.enteredPin = "";
                    this.acceptablePins = [];
                    this.tempBankData = null;
                }
                this.isLoading = false;
                axios.post(`https://${GetParentResourceName()}/closeApp`, {});
            }, 1500);
        },
    },
    mounted() {
        document.addEventListener("keydown", this.handleKeydown);
        window.addEventListener("message", this.handleMessage);
    },
    beforeUnmount() {
        document.removeEventListener("keydown", this.handleKeydown);
    },
}).mount("#app");
