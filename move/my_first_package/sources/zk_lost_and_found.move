module my_first_package::zk_lost_and_found {

    // Part 1: Imports
    // use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::event;
    // use sui::vec_map::{Self, VecMap};
    // use sui_system::staking_pool::StakedSui;
    // use sui_system::sui_system::{Self, SuiSystemState};
    use sui::hash;
    use std::debug;
    

    // const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const ITEM_IS_NOT_LOST: u64 = 2;
    const ITEM_ALREADY_FOUND: u64 = 0;
    const ITEM_MUST_BE_FOUND_FIRST: u64 = 3;

    // Part 2: Struct definitions

    struct LostItem has key, store {
        id: UID,
        hash: String,
        owner: address,
        reward: u64,
        is_found: bool,
    }

    struct LostItems has key {
        id: UID,
        owner: address,
        counter: u64,
        balance: Balance<SUI>,
        items: ObjectTable<String, LostItem>,
    }

    struct FoundItem has key, store {
        id: UID,
        hash: String,
        finder: address,
        owner: address,
        reward: u64,
        is_owner_found: bool,
    }

    struct FoundItems has key {
        id: UID,
        owner: address,
        counter: u64,
        balance: Balance<SUI>,
        items: ObjectTable<String, FoundItem>,
    }

    struct FinderContract has key, store {
        id: UID,
        email: String,
        owner: address,
    }

    // This is an event
    // This event will be emitted in the found_lost_item function
    struct LostItemCreated has copy, drop {
        hash: String,
        owner: address,
        reward: u64,
    }

    // This is an event
    // This event will be emitted in the found_lost_item function
    struct ItemFound has copy, drop {
        hash: String,
        owner: address,
    }


    // This event will be emitted in the found_lost_item function
    struct FoundItemCreated has copy, drop {
        hash: String,
        finder: address,
    }

    // This is an event
    // This event will be emitted in the found_lost_item function
    struct OwnerFound has copy, drop {
        hash: String,
        owner: address,
        reward: u64,
    }


    // Part 3: Module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            LostItems {
                id: object::new(ctx),
                owner: tx_context::sender(ctx),
                counter: 0,
                balance: balance::zero(),
                items: object_table::new(ctx),
            }
        );

        transfer::share_object(
            FoundItems {
                id: object::new(ctx),
                owner: tx_context::sender(ctx),
                counter: 0,
                balance: balance::zero(),
                items: object_table::new(ctx),
            }
        );
    }


    //////////////////////////////////////////
    // PART 1
    // If you lost an object and you want to find it

    public entry fun create_lost_item(data: vector<u8>, payment: Coin<SUI>, lost_items: &mut LostItems, ctx: &mut TxContext) {
        let value = 100;
        // let value_coin: u64 = coin::value(&payment);
        let value_coin = coin::value(&payment); // get the tokens transferred with the transaction
        assert!( value_coin >= value, INSUFFICIENT_FUNDS); // check if the sent amount is correct
        // transfer::public_transfer(payment, lost_items.owner); // tranfer the tokens

        // let coin_balance = coin::into_balance(payment);
        // let paid = balance::split(&mut coin_balance, value);

        // Here we increase the counter before adding the item to the table
        lost_items.counter = lost_items.counter + 1;

        // Create new id
        // Id is created here because we are going to use it with both devcard and the event
        let id = object::new(ctx);
        let hash: vector<u8> = hash::keccak256(&data);

        // Creating the new LostItem
        let item = LostItem {
            id: id,
            hash: string::utf8(hash),
            owner: tx_context::sender(ctx),
            reward: value,
            is_found: false,
        };

        // Adding item to the table
        object_table::add(&mut lost_items.items, string::utf8(hash), item);

        // Emit the event
        event::emit(
            LostItemCreated { 
                hash: string::utf8(hash),
                owner: tx_context::sender(ctx),
                reward: value,
            }
        );

        // Transfer the reward to the address
        coin::put(&mut lost_items.balance, payment);
        // balance::join(&mut lost_items.balance, payment);
    }

    public entry fun found_lost_item(data: vector<u8>, contact_email: vector<u8>, lost_items: &mut LostItems, ctx: &mut TxContext) {
        let hash = hash::keccak256(&data);
        let is_exist: bool = object_table::contains(&lost_items.items, string::utf8(hash));
        // debug::print(&is_exist);
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let lost_item = object_table::borrow_mut(&mut lost_items.items, string::utf8(hash));
        assert!(lost_item.is_found == false, ITEM_ALREADY_FOUND);
        lost_item.is_found = true;

        // Emit the event
        event::emit(
            ItemFound { 
                hash: string::utf8(hash),
                owner: lost_item.owner,
            }
        );

        // Transfer the reward to the finder
        let amount = 100;
        // transfer::public_transfer(&mut lost_items.balance, tx_context::sender(ctx));
        let reward = coin::take(&mut lost_items.balance, amount, ctx);
        transfer::public_transfer(reward, tx_context::sender(ctx));
        

        // Send finder contract information to the address who lost item
        let finder_contract = FinderContract {
            id: object::new(ctx),
            email: string::utf8(contact_email),
            owner: tx_context::sender(ctx),
        };
        transfer::transfer(finder_contract, lost_item.owner);
    }


    // This is the same as create_lost_item but it takes the hash as an argument data is not send to the blockchain 
    public entry fun create_lost_item_hash(hash: vector<u8>, payment: Coin<SUI>, lost_items: &mut LostItems, ctx: &mut TxContext) {
        let value = 100;
        // let value_coin: u64 = coin::value(&payment);
        let value_coin = coin::value(&payment); // get the tokens transferred with the transaction
        assert!( value_coin >= value, INSUFFICIENT_FUNDS); // check if the sent amount is correct
        // transfer::public_transfer(payment, lost_items.owner); // tranfer the tokens

        // let coin_balance = coin::into_balance(payment);
        // let paid = balance::split(&mut coin_balance, value);

        // Here we increase the counter before adding the item to the table
        lost_items.counter = lost_items.counter + 1;

        // Create new id
        // Id is created here because we are going to use it with both devcard and the event
        let id = object::new(ctx);

        // Creating the new LostItem
        let item = LostItem {
            id: id,
            hash: string::utf8(hash),
            owner: tx_context::sender(ctx),
            reward: value,
            is_found: false,
        };

        // Adding item to the table
        object_table::add(&mut lost_items.items, string::utf8(hash), item);

        // Emit the event
        event::emit(
            LostItemCreated { 
                hash: string::utf8(hash),
                owner: tx_context::sender(ctx),
                reward: value,
            }
        );

        // Transfer the reward to the address
        coin::put(&mut lost_items.balance, payment);
        // balance::join(&mut lost_items.balance, payment);
    }

    // This is the same as found_lost_item but it takes the hash as an argument data is not send to the blockchain
    public entry fun found_lost_item_hash(hash: vector<u8>, contact_email: vector<u8>, lost_items: &mut LostItems, ctx: &mut TxContext) {
        let is_exist: bool = object_table::contains(&lost_items.items, string::utf8(hash));
        // debug::print(&is_exist);
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let lost_item = object_table::borrow_mut(&mut lost_items.items, string::utf8(hash));
        assert!(lost_item.is_found == false, ITEM_ALREADY_FOUND);
        lost_item.is_found = true;

        // Emit the event
        event::emit(
            ItemFound { 
                hash: string::utf8(hash),
                owner: lost_item.owner,
            }
        );

        // Transfer the reward to the finder
        let amount = 100;
        // transfer::public_transfer(&mut lost_items.balance, tx_context::sender(ctx));
        let reward = coin::take(&mut lost_items.balance, amount, ctx);
        transfer::public_transfer(reward, tx_context::sender(ctx));
        

        // Send finder contract information to the address who lost item
        let finder_contract = FinderContract {
            id: object::new(ctx),
            email: string::utf8(contact_email),
            owner: tx_context::sender(ctx),
        };
        transfer::transfer(finder_contract, lost_item.owner);
    }


    //////////////////////////////////////////
    // PART 2
    // If lost object is found before the owner declares it lost

    // If you find a lost object you can create a found item if nobody creates there is a lost item
    public entry fun create_found_item(data: vector<u8>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        // Here we increase the counter before adding the item to the table
        found_items.counter = found_items.counter + 1;

        // Create new id
        // Id is created here because we are going to use it with both devcard and the event
        let id = object::new(ctx);
        let hash: vector<u8> = hash::keccak256(&data);

        // Creating the new LostItem
        let item = FoundItem {
            id: id,
            hash: string::utf8(hash),
            finder: tx_context::sender(ctx),
            owner: sui::address::from_u256(0),   // Null address since we don't know the owner yet
            reward: 100,
            is_owner_found: false,
        };

        // Adding item to the table
        object_table::add(&mut found_items.items, string::utf8(hash), item);

        // Emit the event
        event::emit(
            FoundItemCreated { 
                hash: string::utf8(hash),
                finder: tx_context::sender(ctx),
            }
        );
    }

    // If you lost object you can check if somobody found it
    public entry fun found_owner(data: vector<u8>, payment: Coin<SUI>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        let hash = hash::keccak256(&data);
        let is_exist: bool = object_table::contains(&found_items.items, string::utf8(hash));
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let found_item = object_table::borrow_mut(&mut found_items.items, string::utf8(hash));
        assert!(found_item.is_owner_found == false, ITEM_ALREADY_FOUND);
        found_item.is_owner_found = true;
        // Set the owner of the item
        found_item.owner = tx_context::sender(ctx);

        let value = 100;
        // let value_coin: u64 = coin::value(&payment);
        let value_coin = coin::value(&payment); // get the tokens transferred with the transaction
        assert!( value_coin >= value, INSUFFICIENT_FUNDS); // check if the sent amount is correct

        // Emit the event
        event::emit(
            OwnerFound { 
                hash: string::utf8(hash),
                owner: tx_context::sender(ctx),
                reward: found_item.reward,
            }
        );

        // Transfer the reward to the balance
        coin::put(&mut found_items.balance, payment);
    }

    // If somobody found your object he-she can share his-her email and get the reward
    public entry fun share_email_and_get_reward(data: vector<u8>,  contact_email: vector<u8>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        let hash = hash::keccak256(&data);
        let is_exist: bool = object_table::contains(&found_items.items, string::utf8(hash));
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let found_item = object_table::borrow_mut(&mut found_items.items, string::utf8(hash));
        assert!(found_item.is_owner_found == true, ITEM_MUST_BE_FOUND_FIRST);

        // Transfer the reward to the finder
        let amount = 100;
        let reward = coin::take(&mut found_items.balance, amount, ctx);
        transfer::public_transfer(reward, tx_context::sender(ctx));

       // Send finder contract information to the address who lost item
        let finder_contract = FinderContract {
            id: object::new(ctx),
            email: string::utf8(contact_email),
            owner: tx_context::sender(ctx),
        };
        transfer::transfer(finder_contract, found_item.owner);
    }
        
    // This is the same as create_found_item but it takes the hash as an argument data is not send to the blockchain
    public entry fun create_found_item_hash(hash: vector<u8>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        // Here we increase the counter before adding the item to the table
        found_items.counter = found_items.counter + 1;

        // Create new id
        // Id is created here because we are going to use it with both devcard and the event
        let id = object::new(ctx);

        // Creating the new LostItem
        let item = FoundItem {
            id: id,
            hash: string::utf8(hash),
            finder: tx_context::sender(ctx),
            owner: sui::address::from_u256(0),   // Null address since we don't know the owner yet
            reward: 100,
            is_owner_found: false,
        };

        // Adding item to the table
        object_table::add(&mut found_items.items, string::utf8(hash), item);

        // Emit the event
        event::emit(
            FoundItemCreated { 
                hash: string::utf8(hash),
                finder: tx_context::sender(ctx),
            }
        );
    }

    // This is the same as found_owner but it takes the hash as an argument data is not send to the blockchain
    public entry fun found_owner_hash(hash: vector<u8>, payment: Coin<SUI>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        let is_exist: bool = object_table::contains(&found_items.items, string::utf8(hash));
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let found_item = object_table::borrow_mut(&mut found_items.items, string::utf8(hash));
        assert!(found_item.is_owner_found == false, ITEM_ALREADY_FOUND);
        found_item.is_owner_found = true;
        // Set the owner of the item
        found_item.owner = tx_context::sender(ctx);

        let value = 100;
        // let value_coin: u64 = coin::value(&payment);
        let value_coin = coin::value(&payment); // get the tokens transferred with the transaction
        assert!( value_coin >= value, INSUFFICIENT_FUNDS); // check if the sent amount is correct

        // Emit the event
        event::emit(
            OwnerFound { 
                hash: string::utf8(hash),
                owner: tx_context::sender(ctx),
                reward: found_item.reward,
            }
        );

        // Transfer the reward to the balance
        coin::put(&mut found_items.balance, payment);
    }

    // This is the same as share_email_and_get_reward but it takes the hash as an argument data is not send to the blockchain
    public entry fun share_email_and_get_reward_hash(hash: vector<u8>,  contact_email: vector<u8>, found_items: &mut FoundItems, ctx: &mut TxContext) {
        let is_exist: bool = object_table::contains(&found_items.items, string::utf8(hash));
        assert!(is_exist, ITEM_IS_NOT_LOST);
        let found_item = object_table::borrow_mut(&mut found_items.items, string::utf8(hash));
        assert!(found_item.is_owner_found == true, ITEM_MUST_BE_FOUND_FIRST);

        // Transfer the reward to the finder
        let amount = 100;
        let reward = coin::take(&mut found_items.balance, amount, ctx);
        transfer::public_transfer(reward, tx_context::sender(ctx));

       // Send finder contract information to the address who lost item
        let finder_contract = FinderContract {
            id: object::new(ctx),
            email: string::utf8(contact_email),
            owner: tx_context::sender(ctx),
        };
        transfer::transfer(finder_contract, found_item.owner);
    }


    public fun finder_email(finder_contract: &FinderContract): &String {
        &finder_contract.email
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
    
}