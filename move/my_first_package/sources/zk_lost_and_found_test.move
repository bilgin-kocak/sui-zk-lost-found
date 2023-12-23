#[test_only]
module my_first_package::zk_lost_and_found_test {
    use sui::test_scenario;
    use my_first_package::zk_lost_and_found::{Self, LostItems, LostItem};
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

}