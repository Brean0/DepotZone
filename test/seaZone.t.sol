pragma solidity ^0.8.13;

import { EarnedBeanOracle } from "../src/oracle/EarnedBeanOracle.sol";
import { DepotZone } from "../src/DepotZone.sol";
import { IBeanstalk, IERC20 } from "../src/Depot.sol";
import "../src/interfaces/IPipeline.sol";
import { DepotFacet } from "../src/facets/DepotFacet.sol";
import {Users} from "./utils/Users.sol";


import "forge-std/Test.sol";
import "seaport/contracts/lib/ConsiderationStructs.sol";
import "forge-std/console.sol";
import "seaport/contracts/interfaces/SeaportInterface.sol";

contract seaZone is Test {
    EarnedBeanOracle earnedBeanOracle;
    DepotZone depotZone;
    address constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address constant BEANSTALK = 0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5;
    SeaportInterface seaport = SeaportInterface(0x00000000000001ad428e4906aE43D8F9852d0dD6);
    bytes farmEncoded;
    bytes sig;
    Users users;
    address user;
    address user2;

    function setUp() public {
        initUsers();
        deal(BEAN, user, 1e6);
        depotZone = new DepotZone();
        earnedBeanOracle = new EarnedBeanOracle();
        console.log("Address of depotZone:", address(depotZone));
        console.log("Address of earnedBeanOracle:", address(earnedBeanOracle));
    }

    function testSeaport() public {
        OrderParameters memory order = setUpOrder();
        executeOrder(order);
    }

    function setUpOrder() prank(user) public returns (OrderParameters memory) {
        vm.pauseGasMetering();
        IERC20(BEAN).approve(address(seaport), 1e6);
        OfferItem[] memory offerItem = new OfferItem[](1);
        offerItem[0] = OfferItem(
            ItemType.ERC20, // item offered is an ERC20 token
            BEAN, // the token is BEAN
            0, // the identifier is 0, as we're not using an identifier
            1e6, // the start amount is 1e6
            1e6 // the end amount is 1e6
        );
        // we don't need a consideration item, as the "item" we're considering is the plant
        ConsiderationItem[] memory considerationItem = new ConsiderationItem[](1);
        considerationItem[0] = ConsiderationItem(
            ItemType.NATIVE, // item offered is native (but actually nothing)
            address(0), // the token is 0x0
            0, // the identifier is 0, as we're not using an identifier
            0, // the start amount is 0
            0, //  the end amount is 0
            payable(0) // the recipient is 0x0
        );

        // create the farm call (we cannot do a plant as beanstalk has not updated yet)): 
        // we do 2 pipe calls:
        // the first call verifies the order is valid (i.e. the user has 100 grown stalk)
        // if the user does not, we revert the function
        // the second call performs the update
        PipeCall memory _pipeCall;
        bytes memory pipeData1 = abi.encodeWithSelector(
            EarnedBeanOracle.checkGrownStalkBalance.selector,
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266), 
            0
        );
        _pipeCall.target = address(earnedBeanOracle);
        _pipeCall.data = pipeData1;

        bytes memory data1 = abi.encodeWithSelector(
            DepotFacet.validPipe.selector,
            _pipeCall
        );

        bytes memory pipeData2 = abi.encodeWithSelector(
            IBeanstalk.update.selector,
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
        );
        _pipeCall.target = address(BEANSTALK);
        _pipeCall.data = pipeData2;
        bytes memory data2 = abi.encodeWithSelector(
            DepotFacet.pipe.selector,
            _pipeCall
        );

        
        // create the farm call: 
        bytes[] memory _farmCalls = new bytes[](2);
        _farmCalls[0] =  data1;
        _farmCalls[1] =  data2;

        
        // encode and hash
        farmEncoded = abi.encode(_farmCalls);
        bytes32 dataHash = keccak256(farmEncoded);


        OrderParameters memory _orderParams = OrderParameters(
            address(user), // offerer
            address(depotZone), // zone
            offerItem, // offer
            considerationItem, // consideration
            OrderType.PARTIAL_RESTRICTED, // orderType
            0, // startTime
            2**256 - 1, // endTime
            dataHash, // zoneHash
            0, // salt
            bytes32(0), // conduitKey
            1 // totalOriginalConsiderationItems
        );
        
        // validate signature on-chain: 
        Order memory _order = Order(
            _orderParams, // order parameters
            "" // signature (not needed as we're calling validateSignature)
        );
        
        Order[] memory __order = new Order[](1);
        __order[0] = _order;
        vm.resumeGasMetering();
        bool validated = seaport.validate(__order);
        console.log("validated:", validated);

        return _orderParams;
    }

    function executeOrder(OrderParameters memory orderParams) prank(user2) public {
        vm.pauseGasMetering();

        // create the advancedOrder: 
        AdvancedOrder memory advancedOrder = AdvancedOrder(
            orderParams,
            1,
            1,
            sig,
            farmEncoded
        );
        // execute the order 
        AdvancedOrder[] memory _advancedOrder = new AdvancedOrder[](1);
        _advancedOrder[0] = advancedOrder;
        vm.resumeGasMetering();
        depotZone.executeMatchAdvancedOrders(
            seaport,
            _advancedOrder,
            new CriteriaResolver[](0),
            new Fulfillment[](0)
        );

    }

    function initUsers() internal {
        users = new Users();
        address[] memory _user = new address[](2);
        _user = users.createUsers(2);
        user = _user[0];
        user2 = _user[1];
    }

    modifier prank(address from) {
        vm.startPrank(from);
        _;
        vm.stopPrank();
    }
}
