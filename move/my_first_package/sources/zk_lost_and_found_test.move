#[test_only]
module my_first_package::zk_lost_and_found_test {
    use sui::test_scenario;
    use my_first_package::zk_lost_and_found::{Self, LostItems, LostItem, FoundItem, FoundItems};
    use sui::coin;
    use sui::sui::SUI;

    #[test]
    fun test_create_lost_item() {

        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            zk_lost_and_found::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let lost_items = test_scenario::take_shared<LostItems>(scenario);
            let coin: coin::Coin<SUI>  = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            zk_lost_and_found::create_lost_item_hash(b"hashhashhash", coin, &mut lost_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(lost_items);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_lost_item_found() {

        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            zk_lost_and_found::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, user1);
        {
            let lost_items = test_scenario::take_shared<LostItems>(scenario);
            let coin: coin::Coin<SUI>  = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            zk_lost_and_found::create_lost_item_hash(b"hashhashhash", coin, &mut lost_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(lost_items);
        };

        test_scenario::next_tx(scenario, user2);
        {
            let lost_items = test_scenario::take_shared<LostItems>(scenario);
            zk_lost_and_found::found_lost_item_hash(b"hashhashhash", b"kocakbilgin@gmail.com", &mut lost_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(lost_items);
        };
        
        test_scenario::end(scenario_val);
    }

    // We expect this test to fail with abort code ITEM_IS_NOT_LOST
    #[test]
    #[expected_failure(abort_code = zk_lost_and_found::ITEM_IS_NOT_LOST)]
    fun test_lost_item_not_found() {

        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            zk_lost_and_found::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, user1);
        {
            let lost_items = test_scenario::take_shared<LostItems>(scenario);
            let coin: coin::Coin<SUI>  = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            zk_lost_and_found::create_lost_item_hash(b"hashhashhash", coin, &mut lost_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(lost_items);
        };

        test_scenario::next_tx(scenario, user2);
        {
            let lost_items = test_scenario::take_shared<LostItems>(scenario);
            zk_lost_and_found::found_lost_item_hash(b"wronghash", b"kocakbilgin@gmail.com", &mut lost_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(lost_items);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_create_found_item() {

        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            zk_lost_and_found::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let found_items = test_scenario::take_shared<FoundItems>(scenario);
            zk_lost_and_found::create_found_item_hash(b"hashhashhash", &mut found_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(found_items);
        };
        
        test_scenario::end(scenario_val);
    }


     #[test]
    fun test_found_owner() {

        let owner = @0xA;
        let user1 = @0xB;
        let user2 = @0xC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            zk_lost_and_found::init_for_testing(test_scenario::ctx(scenario));
        };

        // User 1 found an item which is lost by owner
        test_scenario::next_tx(scenario, user1);
        {
            let found_items = test_scenario::take_shared<FoundItems>(scenario);
            zk_lost_and_found::create_found_item_hash(b"hashhashhash", &mut found_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(found_items);
        };
        // User 2 states that he is the owner of the item (so owner found)
        test_scenario::next_tx(scenario, user2);
        {
            let found_items = test_scenario::take_shared<FoundItems>(scenario);
            let coin: coin::Coin<SUI>  = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            zk_lost_and_found::found_owner_hash(b"hashhashhash", coin, &mut found_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(found_items);
        };

        // User 1 get the reward and send contact information
        test_scenario::next_tx(scenario, user2);
        {
            let found_items = test_scenario::take_shared<FoundItems>(scenario);
            zk_lost_and_found::share_email_and_get_reward_hash(b"hashhashhash", b"kocakbilgin@gmail.com", &mut found_items, test_scenario::ctx(scenario));
            test_scenario::return_shared(found_items);
        };
        
        test_scenario::end(scenario_val);
    }
}