const sample = `
#[starknet::contract]
mod secure_contract {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zeroable::Zeroable;
    use traits::Into;
    
    #[storage]
    struct Storage {
        owner: ContractAddress,
        admin: ContractAddress,
        paused: bool,
        values: LegacyMap<ContractAddress, u256>,
        total_supply: u256,
        whitelist: LegacyMap<ContractAddress, bool>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValueSet: ValueSet,
        WhitelistUpdated: WhitelistUpdated,
        OwnershipTransferred: OwnershipTransferred,
        Paused: Paused,
        Unpaused: Unpaused
    }

    #[derive(Drop, starknet::Event)]
    struct ValueSet {
        user: ContractAddress,
        value: u256,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct WhitelistUpdated {
        user: ContractAddress,
        status: bool
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct Paused {
        by: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct Unpaused {
        by: ContractAddress
    }

    mod Errors {
        const INVALID_CALLER: felt252 = 'Invalid caller';
        const INVALID_VALUE: felt252 = 'Invalid value';
        const CONTRACT_PAUSED: felt252 = 'Contract is paused';
        const NOT_WHITELISTED: felt252 = 'Address not whitelisted';
        const ZERO_ADDRESS: felt252 = 'Zero address not allowed';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        assert(!owner.is_zero(), Errors::ZERO_ADDRESS);
        self.owner.write(owner);
        self.admin.write(owner);
        self.paused.write(false);
        self.total_supply.write(0);
    }

    #[abi(embed_v0)]
    impl SecureContract of super::ISecureContract<ContractState> {
        fn set_value(ref self: ContractState, value: u256) {
            // Input validation
            assert(!value.is_zero(), Errors::INVALID_VALUE);
            
            // State checks
            assert(!self.paused.read(), Errors::CONTRACT_PAUSED);
            
            let caller = get_caller_address();
            assert(self.whitelist.read(caller), Errors::NOT_WHITELISTED);

            // Effects
            self.values.write(caller, value);
            self.total_supply.write(self.total_supply.read() + value);

            // Events
            self.emit(ValueSet {
                user: caller,
                value,
                timestamp: get_block_timestamp()
            });
        }

        fn get_value(self: @ContractState, user: ContractAddress) -> u256 {
            assert(!user.is_zero(), Errors::ZERO_ADDRESS);
            self.values.read(user)
        }

        fn update_whitelist(ref self: ContractState, user: ContractAddress, status: bool) {
            self.only_owner();
            assert(!user.is_zero(), Errors::ZERO_ADDRESS);
            
            self.whitelist.write(user, status);
            
            self.emit(WhitelistUpdated { user, status });
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.only_owner();
            assert(!new_owner.is_zero(), Errors::ZERO_ADDRESS);
            
            let previous_owner = self.owner.read();
            self.owner.write(new_owner);
            
            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }

        fn pause(ref self: ContractState) {
            self.only_admin();
            assert(!self.paused.read(), 'Already paused');
            
            self.paused.write(true);
            self.emit(Paused { by: get_caller_address() });
        }

        fn unpause(ref self: ContractState) {
            self.only_admin();
            assert(self.paused.read(), 'Not paused');
            
            self.paused.write(false);
            self.emit(Unpaused { by: get_caller_address() });
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn only_owner(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), Errors::INVALID_CALLER);
        }

        fn only_admin(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), Errors::INVALID_CALLER);
        }
    }
}

#[starknet::interface]
trait ISecureContract<TContractState> {
    fn set_value(ref self: TContractState, value: u256);
    fn get_value(self: @TContractState, user: ContractAddress) -> u256;
    fn update_whitelist(ref self: TContractState, user: ContractAddress, status: bool);
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
}
`;

export default sample;