
import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Int32 "mo:base/Int32";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Map "mo:base/HashMap";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import TokenTypes "./lib/Internals";
import AID "./lib/AID";
import EAID "./lib/EAID";
import Hex "./lib/Hex";
import Binary "./lib/Binary";
import SHA224 "./lib/SHA224";
import DRC202 "./lib/DRC202";
import ICRC1 "./lib/ICRC1";
import Internals "./lib/Internals";
import MotokoNft "./lib/MotokoNFT";
import Error "mo:base/Error";
import Cap "Cap";
import Root "Root";

shared(msg) actor class ICRC1Canister(args : {tokenOwner : Principal}) = this {

    type Metadata = TokenTypes.Metadata;
    type Gas = TokenTypes.Gas;
    type Address = TokenTypes.Address;
    type AccountId = TokenTypes.AccountId;
    type Txid = TokenTypes.Txid;
    type TxnResult = TokenTypes.TxnResult;
    type Operation = TokenTypes.Operation;
    type Transaction = TokenTypes.Transaction;
    // follows ic.house supported structure
    type TxnRecord = TokenTypes.TxnRecord;
    type From = Address;
    type To = Address;
    type Amount = Nat;
    type Sa = [Nat8];
    type Data = Blob;
    type Timeout = Nat32;

    /*
    * account functions
    */
    private func _getAccountId(_address: Address): AccountId{
        switch (AID.accountHexToAccountBlob(_address)){
            case(?(a)){
                return a;
            };
            case(_){
                var p = Principal.fromText(_address);
                var a = AID.principalToAccountBlob(p, null);
                return a;
            };
        };
    };


    /*
    * Config 
    */
    private stable var FEE_TO: AccountId = _getAccountId(Principal.toText(args.tokenOwner));
    /* 
    * State Variables 
    */
    private var standard_: Text = "icrc1";
    private stable var name_: Text = "Motoko";
    private stable var capRootBucketId = "yjx56-laaaa-aaaah-adwya-cai"; // cap bucket of the token
    private stable var symbol_: Text = "MOTOKO";
    private stable let decimals__: Nat8 = 8; // make decimals immutable across upgrades
    private stable var totalSupply_: Nat = 1000000000000; // 10000 $MOTOKO
    private stable var fee_: Nat = 1000; // 0.00001 $MOTOKO
    private stable var metadata_: [Metadata] = [
        {
            // logo from collection image
            content = "data:image/png;base64,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";
            name = "logo";
        }
    ];
    private stable var index: Nat = 0;
    private stable var balances: Trie.Trie<AccountId, Nat> = Trie.empty();
    private var cap: ?Cap.Cap = null;
    private var drc202 = DRC202.DRC202({EN_DEBUG = false; MAX_CACHE_TIME = 3 * 30 * 24 * 3600 * 1000000000; MAX_CACHE_NUMBER_PER = 100; MAX_STORAGE_TRIES = 2; }, standard_);
    private stable var drc202_lastStorageTime : Time.Time = 0;
    
    let motoko_nft : MotokoNft.Self = actor("oeee4-qaaaa-aaaak-qaaeq-cai"); // official Motoko NFT snapshot

    /* 
    * Local Functions
    */
    private func keyb(t: Blob) : Trie.Key<Blob> { return { key = t; hash = Blob.hash(t) }; };

    private func _getAccountIdFromPrincipal(_p: Principal, _sa: ?[Nat8]): AccountId{
        var a = AID.principalToAccountBlob(_p, _sa);
        return a;
    };     
    private stable let owner_: AccountId = AID.principalToAccountBlob(
        args.tokenOwner, ?Internals.minter_subaccount
    );
    private stable let owner_account: Account = { owner = args.tokenOwner; subaccount = ?Blob.fromArray(Internals.minter_subaccount); };

    private func _getBalance(_a: AccountId): Nat{
        switch(Trie.get(balances, keyb(_a), Blob.equal)){
            case(?(balance)){
                return balance;
            };
            case(_){
                return 0;
            };
        };
    };
    private func _setBalance(_a: AccountId, _v: Nat): (){
        let originalValue = _getBalance(_a);
        let now = Time.now();
        if(_v == 0){
            balances := Trie.remove(balances, keyb(_a), Blob.equal).0;
        } else {
            balances := Trie.put(balances, keyb(_a), Blob.equal, _v).0;
            if (_v < fee_ / 2){
                balances := Trie.remove(balances, keyb(_a), Blob.equal).0;
            };
        };
    };
    
    private func _checkFee(_caller: AccountId, _amount: Nat): Bool{
        if(fee_ > 0) {
            return _getBalance(_caller) >= fee_ + _amount;
        };
        return true;
    };
    private func _chargeFee(_caller: AccountId): Bool{
        if(fee_ > 0) {
            if (_getBalance(_caller) >= fee_){
                ignore _send(_caller, FEE_TO, fee_, false);
                return true;
            } else {
                return false;
            };
        };
        return true;
    };
    private func _send(_from: AccountId, _to: AccountId, _value: Nat, _isCheck: Bool): Bool{
        var balance_from = _getBalance(_from);
        if (balance_from >= _value){
            if (not(_isCheck)) { 
                balance_from -= _value;
                _setBalance(_from, balance_from);
                var balance_to = _getBalance(_to);
                balance_to += _value;
                _setBalance(_to, balance_to);
            };
            return true;
        } else {
            return false;
        };
    };
    private func _mint(_to: AccountId, _value: Nat): Bool{
        var balance_to = _getBalance(_to);
        balance_to += _value;
        _setBalance(_to, balance_to);
        totalSupply_ += _value;
        return true;
    };
    private func _burn(_from: AccountId, _value: Nat, _isCheck: Bool): Bool{
        var balance_from = _getBalance(_from);
        if (balance_from >= _value){
            if (not(_isCheck)) {
                balance_from -= _value;
                _setBalance(_from, balance_from);
                totalSupply_ -= _value;
            };
            return true;
        } else {
            return false;
        };
    };

    private func _transfer(_msgCaller: Principal, _sa: ?[Nat8], _from: AccountId, _to: AccountId, _value: Nat, _data: ?Blob, 
    _operation: Operation): (result: TxnResult) {
        var callerPrincipal = _msgCaller;
        let caller = _getAccountIdFromPrincipal(_msgCaller, _sa);
        let from = _from;
        let to = _to;
        let value = _value; 
        var allowed: Nat = 0; // *
        var spendValue = _value;
        var effectiveFee : Internals.Gas = #token(fee_);
        let data = Option.get(_data, Blob.fromArray([]));

        if (data.size() > 2048){
            // drc202 limitations
            return #err({ code=#UndefinedError; message="The length of _data must be less than 2 KB"; });
        };
        switch(_operation){
            case(#transfer(operation)){
                switch(operation.action){
                    case(#mint){ effectiveFee := #noFee;};
                    case(_){};
                };
            };
        };
        let nonce = index;
        let txid = drc202.generateTxid(Principal.fromActor(this), caller, nonce);
        var txn: TxnRecord = {
            msgCaller = ?_msgCaller; 
            caller = caller;
            timestamp = Time.now();
            index = index;
            nonce = nonce;
            txid = txid;
            gas = effectiveFee;
            transaction = {
                from = from;
                to = to;
                value = value; 
                operation = _operation;
                data = _data;
            };
        };
        switch(_operation){
            case(#transfer(operation)){
                switch(operation.action){
                    case(#send){
                        if (not(_send(from, to, value, true))){
                            return #err({ code=#InsufficientBalance; message="Insufficient Balance"; });
                        };
                        ignore _send(from, to, value, false);
                        var as: [AccountId] = [from, to];
                        drc202.pushLastTxn(as, txid);
                    };
                    case(#mint){
                        ignore _mint(to, value);
                        var as: [AccountId] = [to];
                        drc202.pushLastTxn(as, txid); 
                        as := AID.arrayAppend(as, [caller]);
                    };
                    case(#burn){
                        if (not(_burn(from, value, true))){
                            return #err({ code=#InsufficientBalance; message="Insufficient Balance"; });
                        };
                        ignore _burn(from, value, false);
                        var as: [AccountId] = [from];
                        drc202.pushLastTxn(as, txid);
                    };
                };
            };
        };
        // insert for drc202 record
        drc202.put(txn);
        index += 1;
        return #ok(txid);
    };

    private func _transferFrom(__caller: Principal, _from: AccountId, _to: AccountId, _value: Amount, _sa: ?Sa, _data: ?Data) : 
    (result: TxnResult) {
        let from = _from;
        let to = _to;
        let operation: Operation = #transfer({ action = #send; });
        // check fee
        if(not(_checkFee(from, _value))){
            return #err({ code=#InsufficientBalance; message="Insufficient Balance"; });
        };
        // transfer
        let res = _transfer(__caller, _sa, from, to, _value, _data, operation);
        // charge fee
        switch(res){
            case(#ok(v)){ ignore _chargeFee(from); return res; };
            case(#err(v)){ return res; };
        };
    };

    public query func historySize() : async Nat {
        return index;
    };

    // icrc1 standard (https://github.com/dfinity/ICRC-1)
    type Value = ICRC1.Value;
    type Subaccount = ICRC1.Subaccount;
    type Account = ICRC1.Account;
    type TransferArgs = ICRC1.TransferArgs;
    type TransferError = ICRC1.TransferError;
    
    private func _icrc1_get_account(_a: Account) : Blob{
        var sub: ?[Nat8] = null;
        switch(_a.subaccount){
            case(?(_sub)){ sub := ?(Blob.toArray(_sub)) };
            case(_){};
        };
        return _getAccountIdFromPrincipal(_a.owner, sub);
    };

    private func _icrc1_receipt(_result: TxnResult, _a: AccountId) : { #Ok: Nat; #Err: TransferError; }{
        switch(_result){
            case(#ok(txid)){
                switch(drc202.get(txid)){
                    case(?(txn)){ return #Ok(txn.index) };
                    case(_){ return #Ok(0) };
                };
            };
            case(#err(err)){
                switch(err.code){
                    case(#UndefinedError) { return #Err(#GenericError({ error_code = 999; message = err.message })) };
                    case(#InsufficientBalance) { return #Err(#InsufficientFunds({ balance = _getBalance(_a); })) };
                };
            };
        };
    };

    private func _toSaNat8(_sa: ?Blob) : ?[Nat8]{
        switch(_sa){
            case(?(sa)){ return ?Blob.toArray(sa); };
            case(_){ return null; };
        }
    };
    private let PERMITTED_DELAY: Int = 180_000_000_000; // 3 minutes
    private func _icrc1_time_check(_created_at_time: ?Nat64) : 
    { #Ok; #TransferErr: TransferError; }{
        switch(_created_at_time){
            case(?(created_at_time)){
                if (Nat64.toNat(created_at_time) + PERMITTED_DELAY < Time.now()){
                    return #TransferErr(#TooOld);
                };
                return #Ok;
            };
            case(_){
                return #Ok;
            };
        };
    };
    public query func icrc1_supported_standards() : async [{ name : Text; url : Text }]{
        return [
            {name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1"},
        ];
    };
    public query func icrc1_minting_account() : async ?Account{
        return ?owner_account;
    };
    public query func icrc1_name() : async Text{
        return name_;
    };
    public query func icrc1_symbol() : async Text{
        return symbol_;
    };
    public query func icrc1_decimals() : async Nat8{
        return decimals__;
    };
    public query func icrc1_fee() : async Nat{
        return fee_;
    };
    public query func icrc1_metadata() : async [(Text, Value)]{
        let md1: [(Text, Value)] = [("icrc1:symbol", #Text(symbol_)), ("icrc1:name", #Text(name_)), ("icrc1:decimals", #Nat(Nat8.toNat(decimals__))), 
        ("icrc1:fee", #Nat(fee_)), ("icrc1:total_supply", #Nat(totalSupply_)), ("icrc1:max_memo_length", #Nat(2048))];
        var md2: [(Text, Value)] = Array.map<Metadata, (Text, Value)>(metadata_, func (item: Metadata) : (Text, Value) {
            if (item.name == "logo"){
                ("icrc1:"#item.name, #Text(item.content))
            }else{
                ("drc20:"#item.name, #Text(item.content))
            }
        });
        return AID.arrayAppend(md1, md2);
    };
    public query func icrc1_total_supply() : async Nat{
        return totalSupply_;
    };
    public query func icrc1_balance_of(_owner: Account) : async (balance: Nat){
        return _getBalance(_icrc1_get_account(_owner));
    };

    public shared(msg) func icrc1_transfer(_args: TransferArgs) : async ({ #Ok: Nat; #Err: TransferError; }) {
        // locked
        // assert(Principal.isController(msg.caller));
        switch(_args.fee){
            case(?(icrc1_fee)){
                if (icrc1_fee < fee_){ return #Err(#BadFee({ expected_fee = fee_ })) };
            };
            case(_){};
        };
        let from = _icrc1_get_account({ owner = msg.caller; subaccount = _args.from_subaccount; });
        let sub = _toSaNat8(_args.from_subaccount);
        let to = _icrc1_get_account(_args.to);
        let data = _args.memo;
        switch(_icrc1_time_check(_args.created_at_time)){
            case(#TransferErr(err)){ return #Err(err); };
            case(_){};
        };
        let res = _transferFrom(msg.caller, from, to, _args.amount, sub, data);

        // Store data to the DRC202 scalable bucket, requires a 20 second interval to initiate a batch store, and may be rejected if you store frequently.
        if (Time.now() > drc202_lastStorageTime + 20*1000000000) { 
            drc202_lastStorageTime := Time.now();
            ignore drc202.store(); 
        };
        ignore addRecord(
            msg.caller, "transfer",
            [
                ("to", #Principal(_args.to.owner)),
                ("value", #U64(u64(_args.amount))),
                ("fee", #U64(u64(fee_)))
            ]
        );
        return _icrc1_receipt(res, from);
    };

    // CAP records
    private func u64(i: Nat): Nat64 {
        Nat64.fromNat(i)
    };

    private func addRecord(
        caller: Principal,
        op: Text, 
        details: [(Text, Root.DetailValue)]
        ): async () {
        let c = switch(cap) {
            case(?c) { c };
            case(_) { Cap.Cap(Principal.fromActor(this), 2_000_000_000_000) };
        };
        cap := ?c;
        let record: Root.IndefiniteEvent = {
            operation = op;
            details = details;
            caller = caller;
        };
        // don't wait for result, faster
        ignore c.insert(record);
    };
    // drc202
    public query func drc202_getConfig() : async DRC202.Setting{
        return drc202.getConfig();
    };

    public query func drc202_canisterId() : async Principal{
        return drc202.drc202CanisterId();
    };
    /// returns events
    public query func drc202_events(_account: ?DRC202.Address) : async [DRC202.TxnRecord]{
        switch(_account){
            case(?(account)){ return drc202.getEvents(?_getAccountId(account)); };
            case(_){return drc202.getEvents(null);}
        };
    };
    /// returns txn record. It's an query method that will try to find txn record in token canister cache.
    public query func drc202_txn(_txid: DRC202.Txid) : async (txn: ?DRC202.TxnRecord){
        return drc202.get(_txid);
    };
    /// returns txn record. It's an update method that will try to find txn record in the DRC202 canister if the record does not exist in this canister.
    public shared func drc202_txn2(_txid: DRC202.Txid) : async (txn: ?DRC202.TxnRecord){
        switch(drc202.get(_txid)){
            case(?(txn)){ return ?txn; };
            case(_){
                return await drc202.get2(Principal.fromActor(this), _txid);
            };
        };
    };
    /// returns drc202 pool
    public query func drc202_pool() : async [(DRC202.Txid, Nat)]{
        return drc202.getPool();
    };

    /* 
    * Genesis
    */
    private stable var genesisCreated: Bool = false;
    if (not(genesisCreated)){
        balances := Trie.put(balances, keyb(owner_), Blob.equal, totalSupply_).0;
        var txn: TxnRecord = {
            txid = Blob.fromArray([0:Nat8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
            msgCaller = ?msg.caller;
            caller = AID.principalToAccountBlob(msg.caller, null);
            timestamp = Time.now();
            index = index;
            nonce = 0;
            gas = #noFee;
            transaction = {
                from = AID.blackhole();
                to = owner_;
                value = totalSupply_; 
                operation = #transfer({ action = #mint; });
                data = null;
            };
        };
        index += 1;
        drc202.put(txn);
        drc202.pushLastTxn([owner_], txn.txid);
        genesisCreated := true;
    };

    private stable var __drc202Data: [DRC202.DataTemp] = [];
    private stable var __drc202DataNew: ?DRC202.DataTemp = null;

    system func preupgrade() {
        __drc202DataNew := ?drc202.getData();
        eligible_tokens := Iter.toArray(eligibleTokens.entries());
        claimed_tokens := Iter.toArray(claimedTokens.entries());
        claimed_txs := Iter.toArray(claimedTxs.entries());
        airdroped_tokens := Iter.toArray(airdropedTokens.entries());
        airdrop_txs := Iter.toArray(airdropTxs.entries());
    };

    system func postupgrade() {
        switch(__drc202DataNew){
            case(?(data)){
                drc202.setData(data);
                __drc202Data := [];
                __drc202DataNew := null;
            };
            case(_){
                if (__drc202Data.size() > 0){
                    drc202.setData(__drc202Data[0]);
                    __drc202Data := [];
                };
            };
        };

        eligibleTokens := Map.fromIter<MotokoNft.AccountIdentifier, Nat>(eligible_tokens.vals(), 1, Text.equal, Text.hash);

        claimedTokens := Map.fromIter<Principal, Nat>(claimed_tokens.vals(), 1, Principal.equal, Principal.hash);
        airdropedTokens := Map.fromIter<Principal, Nat>(airdroped_tokens.vals(), 1, Principal.equal, Principal.hash);

        claimedTxs := Map.fromIter<Principal, Blob>(claimed_txs.vals(), 1, Principal.equal, Principal.hash);
        airdropTxs := Map.fromIter<Principal, Blob>(airdrop_txs.vals(), 1, Principal.equal, Principal.hash);

        eligible_tokens := [];
        
        claimed_tokens := [];
        airdroped_tokens := [];

        claimed_txs := [];
        airdrop_txs := [];
    };

    /** 
      $MOTOKO claim methods & states for transparency
    **/
    type TokenClaimTx = {
        tx : Txid;
        tokens : Nat;
    };
    type TokenClaimStatus = {
        #Airdroped : TokenClaimTx;
        #Claimed : TokenClaimTx;
        #Unclaimed : Nat;
    };

    private stable var raw_snapshot : [(MotokoNft.TokenIndex, MotokoNft.AccountIdentifier)] = [];
    private stable var raw_snapshot_time : Int = 0;
    private stable var snapshotTimer : Timer.TimerId = 0;

    private stable var eligible_tokens : [(MotokoNft.AccountIdentifier, Nat)] = [];
    private var eligibleTokens : Map.HashMap<MotokoNft.AccountIdentifier, Nat> = Map.fromIter(
        eligible_tokens.vals(), 0, 
        Text.equal, Text.hash
    );

    private stable var claimed_tokens : [(Principal, Nat)] = [];
    private var claimedTokens : Map.HashMap<Principal, Nat> = Map.fromIter(
        claimed_tokens.vals(), 0,
        Principal.equal, Principal.hash
    );

    private stable var claimed_txs : [(Principal, Blob)] = [];
    private var claimedTxs : Map.HashMap<Principal, Blob> = Map.fromIter(
        claimed_txs.vals(), 0,
        Principal.equal, Principal.hash
    );

    private stable var airdroped_tokens : [(Principal, Nat)] = [];
    private var airdropedTokens : Map.HashMap<Principal, Nat> = Map.fromIter(
        airdroped_tokens.vals(), 0,
        Principal.equal, Principal.hash
    );

    private stable var airdrop_txs : [(Principal, Blob)] = [];
    private var airdropTxs : Map.HashMap<Principal, Blob> = Map.fromIter(
        airdrop_txs.vals(), 0,
        Principal.equal, Principal.hash
    );


    // helper functions
    private func createEligibleTokenList() {
        // reset before creating new list
        eligible_tokens := [];
        eligibleTokens := Map.fromIter<MotokoNft.AccountIdentifier, Nat>([].vals(), 1, Text.equal, Text.hash);
        for (x in raw_snapshot.vals()) {
            let _tokens = switch(eligibleTokens.get(x.1)){
                case(?c) {c};
                case(_) {0};
            };
            eligibleTokens.put(x.1, _tokens + 1);
        };
        return;
    };

    // Hail the Vikings 
    public composite query func get_transactions(page : Nat32) : async Root.GetTransactionsResponseBorrowed {
        let c : Root.Self = actor(capRootBucketId);
        let transactions = await c.get_transactions({page = ?page; witness = false});
        return transactions;
    };

    public composite query func get_user_transactions(user : Principal, page : Nat32) : async Root.GetTransactionsResponseBorrowed {
        let c : Root.Self = actor(capRootBucketId);
        let transactions = await c.get_user_transactions({page = ?page; user = user; witness = false});
        return transactions;
    };


    public composite query func get_transaction_pages() : async Int64 {
        let c : Root.Self = actor(capRootBucketId);
        let total_txs = Int64.fromNat64(await c.size());
        let pages = total_txs / 64;
        return if(Int64.rem(total_txs, 64) > 0) { pages + 1 } else { pages };
    };

    public composite query func get_transaction(txid : Nat64) : async Root.GetTransactionResponse {
        let c : Root.Self = actor(capRootBucketId);
        let transaction =  await c.get_transaction({id=txid; witness=false;});
        return transaction;
    };

    public query func unclaimedTokens() : async Nat {
        return _getBalance(owner_);
    };

    public query func getRawSnapshot() : async {
        snapshot : [(MotokoNft.TokenIndex, MotokoNft.AccountIdentifier)];
        snapshot_time : Int
    } {
        return {
            snapshot = raw_snapshot;
            snapshot_time = raw_snapshot_time
        };
    };

    public query func getEligibleTokensSnap() : async [(MotokoNft.AccountIdentifier, Nat)] {
        return Iter.toArray(eligibleTokens.entries());
    };

    private func findEligibleTokens(user: Principal) : Nat {
        var totalTokens : Nat = 0;
        let accountIdx : [Nat] = Iter.toArray(Iter.range(0, 50));
        for (i in accountIdx.vals()) {
          let subaccount_array : [Nat8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,Nat8.fromNat(i)];
          let address = EAID.fromPrincipal(user, ?subaccount_array);
          totalTokens += Option.get(eligibleTokens.get(address), 0);
        };
        return totalTokens;
    };

    private func _getEligibleTokenOfUser(user: Principal) : TokenClaimStatus {
        switch(airdropedTokens.get(user)) {
            case(?tokens) {
                return #Airdroped { tx = ""; tokens };
            };
            case(_){};
        };
        switch(claimedTokens.get(user)){
            case(?tokens){

                return #Claimed { tx = ""; tokens };
            };
            case(_){};
        };
        return #Unclaimed(findEligibleTokens(user));
    };

    public shared query(msg) func getEligibleTokenOfUser(user : Principal) : async TokenClaimStatus {
         _getEligibleTokenOfUser(user)
    };

    // updates
    public shared(msg) func createSnap() : async () {
        assert(Principal.isController(msg.caller));
        // Tuesday, January 30, 2024 3:00:00 PM UTC with 1 minute gap
        if(raw_snapshot_time > 0) {
            if(Time.now() < (1706626800000000000) or Time.now() > (1706626860000000000)) {
                throw Error.reject("not allowed in this time");
            };
        };
        raw_snapshot := await motoko_nft.getRegistry();
        raw_snapshot_time := Time.now();
        createEligibleTokenList();
    };

    public shared(msg) func claimTokens() : async TokenClaimStatus {
        assert(Principal.isController(msg.caller));
        if(airdropedTokens.size() < 2301 or claimedTokens.size() < 53){
            throw Error.reject("please connect to the developer");
        };
        switch(_getEligibleTokenOfUser(msg.caller)) {
            case(#Unclaimed(tokens)){
                if(tokens > 0){
                    let user = AID.principalToAccountBlob(msg.caller, null);
                    let tokenAmount = tokens * 100000000;
                    let res = _transferFrom(msg.caller, owner_, user, tokenAmount - fee_, null, null);
                    switch(res) {
                        case(#ok(tx)){
                            claimedTokens.put(msg.caller, tokens);
                            claimedTxs.put(msg.caller, tx);
                            ignore addRecord(
                                msg.caller, "claimTokens",
                                [
                                    ("to", #Principal(msg.caller)),
                                    ("value", #U64(u64(tokenAmount))),
                                    ("fee", #U64(u64(fee_)))
                                ]
                            );

                            return #Claimed { tx; tokens };
                        };
                        case(_){
                            throw Error.reject("unexpected error");
                        };
                    };
                };
                return #Unclaimed(0);
            };

            case(status){
                return status;
            };

        };
    };

    public shared(msg) func airdropTokens(user : Principal) : async TokenClaimStatus {
        
        assert(Principal.isController(msg.caller));

        switch(_getEligibleTokenOfUser(user)){
            case(#Unclaimed(tokens)) {
              if(tokens > 0){
                    let _user = AID.principalToAccountBlob(user, null);
                    let tokenAmount = tokens * 100000000;
                    let res = _transferFrom(msg.caller, owner_, _user, tokenAmount - fee_, null, null);
                    switch(res) {
                        case(#ok(tx)){
                            airdropedTokens.put(user, tokens);
                            airdropTxs.put(user, tx);
                            ignore addRecord(
                                msg.caller, "airdropTokens",
                                [
                                    ("to", #Principal(user)),
                                    ("value", #U64(u64(tokenAmount))),
                                    ("fee", #U64(u64(fee_)))
                                ]
                            );
                            return #Airdroped { tx; tokens };
                        };
                        case(_){
                            throw Error.reject("unexpected error");
                        };
                    };
              };
              return #Unclaimed(0);
            };
            case(status){
                return status;
            };
        };
    };

   public shared(msg) func g_balanceOf(hex : Text) : async (Nat) {
        let account = Option.unwrap(AID.accountHexToAccountBlob(hex));
        let balance = _getBalance(account);
        return balance;
   };

    // public shared(msg) func checkData(start : Nat, end : Nat) : async (Nat, Nat, Nat, Nat) {
    //     assert(Principal.isController(msg.caller));
    //     let affected_pages :[Nat] = Iter.toArray(Iter.range(start, end));
    //     let c : Root.Self = actor(capRootBucketId);
    //     for (page in affected_pages.vals()){
    //         let transactions = await c.get_transactions({page = ?Nat32.fromNat(page); witness = false});
    //         for(event in transactions.data.vals()){
    //             if(event.operation == "claimTokens"){
    //                 var p : Principal = Principal.fromText("aaaaa-aa");
    //                 var v : Nat64 = 0;
    //                 for(details in event.details.vals()) {
    //                     if(details.0 == "to") {
    //                         switch(details.1){
    //                             case(#Principal(user)){
    //                                 p := user;
    //                             };
    //                             case(_){};
    //                         };
    //                     };
    //                     if(details.0 == "value"){
    //                         switch(details.1){
    //                             case(#U64(value)){
    //                                 v := value;
    //                             };
    //                             case(_){};
    //                         };
    //                     };
    //                 };
    //                 if (p != Principal.fromText("aaaaa-aa") and v != 0){
    //                     claimedTokens.put(p, Nat64.toNat(v / 100000000));
    //                 };
    //             };
    //             if(event.operation == "airdropTokens"){
    //                 var p : Principal = Principal.fromText("aaaaa-aa");
    //                 var v : Nat64 = 0;
    //                 for(details in event.details.vals()) {
    //                     if(details.0 == "to") {
    //                         switch(details.1){
    //                             case(#Principal(user)){
    //                                 p := user;
    //                             };
    //                             case(_){};
    //                         };
    //                     };
    //                     if(details.0 == "value"){
    //                         switch(details.1){
    //                             case(#U64(value)){
    //                                 v := value;
    //                             };
    //                             case(_){};
    //                         };
    //                     };
    //                 };
    //                 if (p != Principal.fromText("aaaaa-aa") and v != 0){
    //                     airdropedTokens.put(p, Nat64.toNat(v / 100000000));
    //                 };
    //             };
    //         };
    //     }; 
    //     var aTokens = 0;
    //     var cTokens = 0;
    //     for(x in Iter.toArray(airdropedTokens.entries()).vals()){
    //         aTokens += x.1;
    //     };       
    //     for(x in Iter.toArray(claimedTokens.entries()).vals()){
    //         cTokens += x.1;
    //     };
    //     return (airdropedTokens.size(), claimedTokens.size(), aTokens, cTokens);
    // };
};
