module MyModule::CouponMarketplace {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::string::String;
    
    /// Struct representing a coupon in the marketplace
    struct Coupon has store, key {
        description: String,    // Description of the coupon
        discount_amount: u64,   // Discount amount in percentage or fixed value
        price: u64,             // Price to purchase the coupon
        is_active: bool,        // Whether the coupon is still available
        owner: address,         // Current owner of the coupon
    }
    
    /// Error codes
    const E_COUPON_NOT_ACTIVE: u64 = 1;
    const E_INSUFFICIENT_PAYMENT: u64 = 2;
    const E_COUPON_NOT_FOUND: u64 = 3;
    
    /// Function to create a new coupon and list it in the marketplace
    public fun create_coupon(
        creator: &signer, 
        description: String, 
        discount_amount: u64, 
        price: u64
    ) {
        let creator_addr = signer::address_of(creator);
        let coupon = Coupon {
            description,
            discount_amount,
            price,
            is_active: true,
            owner: creator_addr,
        };
        move_to(creator, coupon);
    }
    
    /// Function to purchase a coupon from the marketplace
    public fun purchase_coupon(
        buyer: &signer, 
        seller_address: address, 
        payment_amount: u64
    ) acquires Coupon {
        // Check if coupon exists
        assert!(exists<Coupon>(seller_address), E_COUPON_NOT_FOUND);
        
        let coupon = borrow_global_mut<Coupon>(seller_address);
        
        // Check if coupon is still active
        assert!(coupon.is_active, E_COUPON_NOT_ACTIVE);
        
        // Check if payment is sufficient
        assert!(payment_amount >= coupon.price, E_INSUFFICIENT_PAYMENT);
        
        // Transfer payment from buyer to seller
        let payment = coin::withdraw<AptosCoin>(buyer, payment_amount);
        coin::deposit<AptosCoin>(seller_address, payment);
        
        // Transfer coupon ownership and deactivate
        coupon.owner = signer::address_of(buyer);
        coupon.is_active = false;
    }
}