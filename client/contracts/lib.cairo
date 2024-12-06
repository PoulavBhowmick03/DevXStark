  # [starknet::contract]
mod contract  {
    use starknet::{ 
        ContractAddress,
        get_caller _address,
        get_contract_address ,
        contract_address_const
     };
    use core::traits::Into; 
    use core::option::OptionT rait;

    #[storage]
     struct Storage {
        owner : ContractAddress,
        pa used: bool,
        bal ances: LegacyMap <ContractAddress, u256>,
        allowances : LegacyMap<(Contract Address, ContractAddress), u256>, 
        total_supply: u256,
     }

    #[event]
    # [derive(Drop, starknet::Event )]
    enum Event {
        Transfer:  Transfer,
        Approval: Approval, 
        OwnershipTransferre d: OwnershipTransferred,
         Paused: Paused,
         Unpaused: Unpaused, 
    }

    #[derive (Drop, starknet::Event)] 
    struct Transfer {
        from : ContractAddress,
        to: Cont ractAddress,
        value: u256, 
    }

    #[derive(Drop , starknet::Event)]
    struct  Approval {
        owner: ContractAddress ,
        spender : ContractAddress, 
        value: u256,
    } 

    #[derive (Drop, starknet::Event)] 
    struct Owner shipTransferred {
        previous _owner: ContractAddress,
        new _owner: ContractAddress,
    } 

    #[derive(Drop, stark net::Event)]
    struct Pause d {
        account: ContractAddress, 
    }

    #[ derive(Drop, starknet::Event)] 
    struct Unpaused {
         account: ContractAddress,
    } 

    #[constructor]
    fn constructor (ref self: Cont ractState, initial_supply : u256, owner : ContractAddress)  {
        assert(! owner.is_zero(),  'Owner cannot be zero'); 
        self.owner.write (owner);
        self.total_supply .write(initial_supply);
         self.balances.write(owner, initial _supply);
         self.emit(Event::Transfer (Transfer { from: contract _address_const::<0>(), to : owner, value: initial_supply })); 
        self.emit(Event ::OwnershipTransferred(Ow nershipTransferred {  previous_owner: contract _address_const::<0>(), new _owner: owner } ));
    } 

    #[external( v0)]
    impl  ContractImpl of super ::IContract<ContractState> { 
        fn transfer(ref  self: ContractState , to: ContractAddress, amount : u256) ->  bool {
            self .assert_not_paused(); 
            let from = get_caller_ address();
            self.transfer _helper(from, to,  amount);
            true
         }

        fn approve (ref self: ContractState, spender : ContractAddress,  amount: u256)  -> bool {
             self.assert_not_paused(); 
            let owner = get_caller_address(); 
            assert(!spender.is_zero (), 'Spender cannot be zero'); 
            self.allowances.write((owner , spender), amount);
            self. emit(Event::Approval(Approval {  owner, spender, value: amount })); 
            true
        }

        fn transfer _from(
            ref self: Cont ractState, from: ContractAddress,  to: ContractAddress , amount: u256 
        ) -> bool {
            self. assert_not_paused();
            let  caller = get_caller_ address();
            let current _allowance = self.allowances.rea d((from, caller));
            assert(current _allowance >= amount, 'Insufficient  allowance');
             self.allowances.write((from , caller), current_allowance - amount); 
            self.transfer_helper(from,  to, amount);
            true
        } 

        fn balance_of(self : @ContractState, account : ContractAddress)  -> u256 {
            self.bal ances.read(account)
        } 

        fn allowance( 
            self: @Cont ractState, owner:  ContractAddress, sp ender: ContractAddress 
        ) -> u 256 {
             self.allowances.read((owner, sp ender))
        }

        fn total_ supply(self: @ContractState) ->  u256 {
            self.total_ supply.read() 
        }

        fn  owner(self: @Cont ractState) -> Cont ractAddress {
             self.owner.rea d()
        } 

        fn paused(self: @ ContractState) ->  bool {
            self.paused.rea d()
        }

        fn transfer _ownership(ref self: ContractState , new_owner:  ContractAddress) { 
            self.assert _only_owner();
             assert(!new_owner. is_zero(), 'New owner cannot be  zero');
            let  previous_owner = self .owner.read();
            self.owner .write(new_ owner);
            self .emit(Event::OwnershipTrans ferred(Owner shipTransferred { previous _owner, new_ owner }));
         }

        fn pause (ref self: Cont ractState) { 
            self.assert_ only_owner();
            assert (!self.pause d.read(), ' Contract already paused');
             self.paused. write(true); 
            self.emit( Event::Pause d(Paused { account: get_caller _address() })); 
        }

         fn unpause(ref self: ContractState ) {
            self .assert_only_ owner();
            assert (self.pause d.read(), ' Contract not paused'); 
            self.paused.write(false );
            self. emit(Event:: Unpaused( Unpaused { account : get_caller_ address() })); 
        }
    }

    # [generate_trait]
    impl  PrivateImpl of  PrivateTrait {
        fn assert_ only_owner(self : @ContractState) { 
            assert(get_caller_address()  == self.owner.read(), ' Caller is not the owner ');
        }

        fn assert_not _paused(self : @ContractState ) {
            assert (!self.pause d.read(), 'Contract is paused'); 
        }

         fn transfer_helper( 
            ref self:  ContractState,
            from: Cont ractAddress,
             to: ContractAddress ,
            amount:  u256
        )  {
            assert(! to.is_zero(),  'Transfer to zero address'); 
            let from_balance = self. balances.read(from);
            assert (from_balance >= amount, ' Insufficient balance');
            self.balances. write(from, from _balance - amount);
            let  to_balance = self .balances.rea d(to);
             self.balances. write(to, to_balance + amount); 
            self.emit (Event::Transfer(Transfer { from, to , value: amount } ));
        } 
    }
}

#[starknet ::interface]
trait  IContract<TCont ractState> { 
    fn transfer(ref self: T ContractState, to : ContractAddress,  amount: u256)  -> bool;
     fn approve(ref self : TContractState , spender: Cont ractAddress, amount:  u256) -> bool;
    fn transfer _from(ref  self: TContract State, from: Cont ractAddress, to:  ContractAddress, amount : u256) ->  bool;
    fn  balance_of(self : @TContract State, account: Cont ractAddress) -> u 256;
    fn  allowance(self:  @TContractState , owner: Contract Address, spender:  ContractAddress) ->  u256;
     fn total_supply( self: @TCont ractState) -> u 256;
    fn  owner(self: @ TContractState)  -> ContractAddress; 
    fn pause d(self: @T ContractState) ->  bool;
    fn  transfer_ownership(ref  self: TContract State, new_owner : ContractAddress); 
    fn pause( ref self: TCont ractState);
     fn unpause(ref  self: TContract State);
}  