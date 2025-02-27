use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use mysaving::IMysavingDispatcher;
use mysaving::IMysavingDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_user_balance_of() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };
    
    // Initial balance should be zero
    let balance = dispatcher.user_balance_of(get_caller_address());
    assert(balance == 0, 'Initial balance should be 0');

    // Deposit and check the balance
    dispatcher.deposit(100);
    let updated_balance = dispatcher.user_balance_of(get_caller_address());
    assert(updated_balance == 100, 'Balance should be 100');
}

#[test]
fn test_get_deposit_history() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };
    
    // Initial deposit history should be zero
    let history = dispatcher.get_deposit_history(get_caller_address());
    assert(history == 0, 'Initial history should be 0');

    // Deposit and check the history
    dispatcher.deposit(100);
    let deposit_history = dispatcher.get_deposit_history(get_caller_address());
    assert(deposit_history == 100, 'Deposit history should be 100');
}

#[test]
fn test_get_withdraw_history() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };

    // Deposit and withdraw
    dispatcher.deposit(100);
    dispatcher.withdraw(50);

    // Check the withdrawal history
    let withdraw_history = dispatcher.get_withdraw_history(get_caller_address());
    assert(withdraw_history == 50, 'Withdraw history should be 50');
}

#[test]
fn test_deposit() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };

    // Deposit and check balance, history, and total supply
    dispatcher.deposit(100);
    let balance = dispatcher.user_balance_of(get_caller_address());
    let deposit_history = dispatcher.get_deposit_history(get_caller_address());
    let total_supply = dispatcher.contract_total_supply();

    assert(balance == 100, 'Balance should be 100');
    assert(deposit_history == 100, 'Deposit history should be 100');
    assert(total_supply == 100, 'Total supply should be 100');
}

#[test]
fn test_withdraw() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };

    // Deposit and withdraw
    dispatcher.deposit(100);
    dispatcher.withdraw(50);

    // Check balance, withdrawal history, and total supply
    let balance = dispatcher.user_balance_of(get_caller_address());
    let withdraw_history = dispatcher.get_withdraw_history(get_caller_address());
    let total_supply = dispatcher.contract_total_supply();

    assert(balance == 50, 'Balance should be 50');
    assert(withdraw_history == 50, 'Withdraw history should be 50');
    assert(total_supply == 50, 'Total supply should be 50');
}

#[test]
fn test_transfer_to() {
    let contract_address = deploy_contract("Mysaving");
    let dispatcher = IMysavingDispatcher { contract_address };
    let caller = get_caller_address();
    
    // Créer une adresse de destinataire fixe
    // Note: cette méthode est rustique mais devrait fonctionner de manière fiable
    let recipient = contract_address;

    // Deposit and transfer
    dispatcher.deposit(100);
    dispatcher.transfer_to(recipient, 30);

    // Check balances
    let sender_balance = dispatcher.user_balance_of(caller);
    let recipient_balance = dispatcher.user_balance_of(recipient);

    assert(sender_balance == 70, 'Sender balance should be 70');
    assert(recipient_balance == 30, 'Recipient balance should be 30');
}

// Fonction pour obtenir l'adresse de l'appelant actuel
fn get_caller_address() -> ContractAddress {
    starknet::get_caller_address()
}
