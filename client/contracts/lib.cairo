#[starknet::contract]
mod contract {
    use starknet::{ContractAddress, get_caller_address};
    use zeroable::Zeroable;
    use traits::Into;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        admins: LegacyMap::<ContractAddress, bool>,
        is_paused: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
        AdminStatusChanged: AdminStatusChanged,
        ContractPaused: ContractPaused,
        ContractUnpaused: ContractUnpaused,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminStatusChanged {
        admin: ContractAddress,
        status: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct ContractPaused {
        by: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct ContractUnpaused {
        by: ContractAddress
    }

    mod Errors {
        const INVALID_ADDRESS: felt252 = 'Invalid address';
        const UNAUTHORIZED: felt252 = 'Unauthorized';
        const ALREADY_INITIALIZED: felt252 = 'Already initialized';
        const CONTRACT_PAUSED: felt252 = 'Contract is paused';
        const CONTRACT_NOT_PAUSED: felt252 = 'Contract not paused';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        assert(!owner.is_zero(), Errors::INVALID_ADDRESS);
        self.owner.write(owner);
        self.admins.write(owner, true);
        self.is_paused.write(false);
    }

    #[external(v0)]
    fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
        self.only_owner();
        assert(!new_owner.is_zero(), Errors::INVALID_ADDRESS);
        
        let previous_owner = self.owner.read();
        self.owner.write(new_owner);
        
        self.emit(Event::OwnershipTransferred(OwnershipTransferred {
            previous_owner: previous_owner,
            new_owner: new_owner,
        }));
    }

    #[external(v0)]
    fn set_admin(ref self: ContractState, admin: ContractAddress, status: bool) {
        self.only_owner();
        assert(!admin.is_zero(), Errors::INVALID_ADDRESS);
        
        self.admins.write(admin, status);
        
        self.emit(Event::AdminStatusChanged(AdminStatusChanged {
            admin: admin,
            status: status,
        }));
    }

    #[external(v0)]
    fn pause(ref self: ContractState) {
        self.only_admin();
        assert(!self.is_paused.read(), Errors::CONTRACT_PAUSED);
        
        self.is_paused.write(true);
        
        self.emit(Event::ContractPaused(ContractPaused {
            by: get_caller_address()
        }));
    }

    #[external(v0)]
    fn unpause(ref self: ContractState) {
        self.only_admin();
        assert(self.is_paused.read(), Errors::CONTRACT_NOT_PAUSED);
        
        self.is_paused.write(false);
        
        self.emit(Event::ContractUnpaused(ContractUnpaused {
            by: get_caller_address()
        }));
    }

    #[view]
    fn get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }

    #[view]
    fn is_admin(self: @ContractState, address: ContractAddress) -> bool {
        self.admins.read(address)
    }

    #[view]
    fn is_contract_paused(self: @ContractState) -> bool {
        self.is_paused.read()
    }

    trait InternalFunctions {
        fn only_owner(ref self: ContractState);
        fn only_admin(ref self: ContractState);
    }

    impl InternalFunctionsImpl of InternalFunctions {
        fn only_owner(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), Errors::UNAUTHORIZED);
        }

        fn only_admin(ref self: ContractState) {
            let caller = get_caller_address();
            assert(self.admins.read(caller), Errors::UNAUTHORIZED);
        }
    }
}