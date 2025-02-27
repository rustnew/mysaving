use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use mysaving::IHelloStarknetSafeDispatcher;
use mysaving::IHelloStarknetSafeDispatcherTrait;
use mysaving::IHelloStarknetDispatcher;
use mysaving::IHelloStarknetDispatcherTrait;

// Fonctions de test pour le contrat Mysaving
#[cfg(test)]
mod tests {
    use super::Mysaving;
    use super::IMysavingDispatcher;
    use super::IMysavingDispatcherTrait;
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};

    // Fonction utilitaire pour déployer le contrat de test
    fn deploy_contract() -> IMysavingDispatcher {
        // Déployer le contrat
        let contract_address = contract_address_const::<0x1>();
        set_contract_address(contract_address);
        
        // Créer une instance de ContractState
        let mut contract_state = Mysaving::unsafe_new_contract_state();
        
        // Initialiser le contrat
        let caller_address = contract_address_const::<0x2>();
        set_caller_address(caller_address);
        
        Mysaving::constructor(ref contract_state);
        
        // Retourner le dispatcher
        IMysavingDispatcher { contract_address }
    }

    #[test]
    fn test_deposit() {
        // Déployer le contrat
        let contract = deploy_contract();
        let user = contract_address_const::<0x3>();
        set_caller_address(user);
        set_block_timestamp(1000);
        
        // Effectuer un dépôt
        let deposit_amount = 100_u256;
        contract.deposit(deposit_amount);
        
        // Vérifier que le solde a été mis à jour
        assert(contract.user_balance_of(user) == deposit_amount, 'Balance not updated');
        
        // Vérifier que l'historique des dépôts a été mis à jour
        assert(contract.get_deposit_history(user) == deposit_amount, 'Deposit history not updated');
        
        // Vérifier que le montant retirable est correct
        assert(contract.get_withdrawable_amount(user) == deposit_amount, 'Withdrawable amount incorrect');
        
        // Vérifier que le total d'approvisionnement a été mis à jour
        assert(contract.contract_total_supply() == deposit_amount, 'Total supply not updated');
    }

    #[test]
    fn test_withdraw() {
        // Déployer le contrat
        let contract = deploy_contract();
        let user = contract_address_const::<0x3>();
        set_caller_address(user);
        set_block_timestamp(1000);
        
        // Effectuer un dépôt
        let deposit_amount = 100_u256;
        contract.deposit(deposit_amount);
        
        // Effectuer un retrait
        let withdraw_amount = 50_u256;
        set_block_timestamp(2000);
        contract.withdraw(withdraw_amount);
        
        // Vérifier que le solde a été mis à jour
        assert(contract.user_balance_of(user) == deposit_amount - withdraw_amount, 'Balance not updated after withdraw');
        
        // Vérifier que l'historique des retraits a été mis à jour
        assert(contract.get_withdraw_history(user) == withdraw_amount, 'Withdraw history not updated');
        
        // Vérifier que le montant retirable est correct
        assert(contract.get_withdrawable_amount(user) == deposit_amount - withdraw_amount, 'Withdrawable amount incorrect after withdraw');
        
        // Vérifier que le total d'approvisionnement a été mis à jour
        assert(contract.contract_total_supply() == deposit_amount - withdraw_amount, 'Total supply not updated after withdraw');
    }

    #[test]
    #[should_panic(expected: ('Cannot withdraw more than deposited',))]
    fn test_withdraw_more_than_deposited() {
        // Déployer le contrat
        let contract = deploy_contract();
        let user = contract_address_const::<0x3>();
        set_caller_address(user);
        
        // Effectuer un dépôt
        let deposit_amount = 100_u256;
        contract.deposit(deposit_amount);
        
        // Effectuer un retrait plus grand que le dépôt
        let withdraw_amount = 150_u256;
        contract.withdraw(withdraw_amount);
        // Ce test devrait échouer
    }

    #[test]
    fn test_transfer_to() {
        // Déployer le contrat
        let contract = deploy_contract();
        let user1 = contract_address_const::<0x3>();
        let user2 = contract_address_const::<0x4>();
        
        // User1 effectue un dépôt
        set_caller_address(user1);
        let deposit_amount = 100_u256;
        contract.deposit(deposit_amount);
        
        // User1 transfère à User2
        let transfer_amount = 30_u256;
        contract.transfer_to(user2, transfer_amount);
        
        // Vérifier les soldes
        assert(contract.user_balance_of(user1) == deposit_amount - transfer_amount, 'User1 balance incorrect');
        assert(contract.user_balance_of(user2) == transfer_amount, 'User2 balance incorrect');
        
        // Le montant retirable de User1 ne change pas (car basé sur les dépôts/retraits)
        assert(contract.get_withdrawable_amount(user1) == deposit_amount, 'User1 withdrawable amount changed');
        
        // User2 ne peut pas retirer car il n'a pas déposé
        assert(contract.get_withdrawable_amount(user2) == 0_u256, 'User2 should not be able to withdraw');
    }

    #[test]
    fn test_multiple_deposits_and_withdrawals() {
        // Déployer le contrat
        let contract = deploy_contract();
        let user = contract_address_const::<0x3>();
        set_caller_address(user);
        
        // Premier dépôt
        contract.deposit(100_u256);
        assert(contract.get_withdrawable_amount(user) == 100_u256, 'Wrong withdrawable amount after first deposit');
        
        // Deuxième dépôt
        contract.deposit(50_u256);
        assert(contract.get_withdrawable_amount(user) == 150_u256, 'Wrong withdrawable amount after second deposit');
        
        // Premier retrait
        contract.withdraw(30_u256);
        assert(contract.get_withdrawable_amount(user) == 120_u256, 'Wrong withdrawable amount after first withdraw');
        
        // Troisième dépôt
        contract.deposit(20_u256);
        assert(contract.get_withdrawable_amount(user) == 140_u256, 'Wrong withdrawable amount after third deposit');
        
        // Deuxième retrait
        contract.withdraw(40_u256);
        assert(contract.get_withdrawable_amount(user) == 100_u256, 'Wrong withdrawable amount after second withdraw');
        
        // Vérifier que le solde total est correct
        assert(contract.user_balance_of(user) == 100_u256, 'Wrong balance after operations');
        
        // Vérifier que les historiques sont corrects
        assert(contract.get_deposit_history(user) == 170_u256, 'Wrong deposit history');
        assert(contract.get_withdraw_history(user) == 70_u256, 'Wrong withdraw history');
    }
}