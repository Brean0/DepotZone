// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { EarnedBeanOracle } from "../src/oracle/EarnedBeanOracle.sol";
import { DepotZone } from "../src/DepotZone.sol";
import { IBeanstalk } from "../src/Depot.sol";
import "../src/interfaces/IPipeline.sol";
import { DepotFacet } from "../src/facets/DepotFacet.sol";

import { Script } from "forge-std/Script.sol";
import "seaport/contracts/lib/ConsiderationStructs.sol";
import "forge-std/console.sol";
import "seaport/contracts/interfaces/SeaportInterface.sol";

abstract contract BaseScript is Script {
    uint internal deployerPrivateKey;

    function setUp() public virtual {
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    }

    modifier broadcaster() {
        vm.startBroadcast(deployerPrivateKey);
        _;
        vm.stopBroadcast();
    }
}

contract MyScript is BaseScript {
    EarnedBeanOracle earnedBeanOracle;
    DepotZone depotZone;
    address constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address constant BEANSTALK = 0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5;
    SeaportInterface seaport = SeaportInterface(0x00000000000001ad428e4906aE43D8F9852d0dD6);

    function run() external broadcaster() {
        // deploy depotZone
        depotZone = new DepotZone();
        // deploy earnedBeanOracle
        earnedBeanOracle = new EarnedBeanOracle();
        console.log("Address of depotZone:", address(depotZone));
        console.log("Address of earnedBeanOracle:", address(earnedBeanOracle));

        // create the order parameters
        

    }

    function setUpOrder() public {
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
        // create the update (we cannot do a plant as beanstalk has not updated yet)): 
        PipeCall memory _pipeCall;
        bytes memory pipeData = abi.encodeWithSelector(IBeanstalk.update.selector, address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        _pipeCall.target = address(BEANSTALK);
        _pipeCall.data = pipeData;
        bytes memory data = abi.encodeWithSelector(
            DepotFacet.pipe.selector,
            _pipeCall
        );

        // create the farm call: 
        bytes[] memory _farmCalls = new bytes[](1);
        _farmCalls[0] =  data;
        
        // encode and hash
        bytes memory farmEncoded = abi.encode(_farmCalls);
        bytes32 dataHash = keccak256(farmEncoded);


        OrderParameters memory orderParams = OrderParameters(
            address(msg.sender), // offerer
            address(depotZone), // zone
            offerItem, // offer
            considerationItem, // consideration
            OrderType.PARTIAL_RESTRICTED, // orderType
            0, // startTime
            0, // endTime
            dataHash, // zoneHash
            0, // salt
            bytes32(0), // conduitKey
            1 // totalOriginalConsiderationItems
        );
        
        // create the signature hash
        bytes memory sig;
        // create the advancedOrder: 
        AdvancedOrder memory advancedOrder = AdvancedOrder(
            orderParams,
            0,
            0,
            sig,
            farmEncoded
        );
        // execute the order 
        AdvancedOrder[] memory _advancedOrder = new AdvancedOrder[](1);
        _advancedOrder[0] = advancedOrder;

        depotZone.executeMatchAdvancedOrders(
            seaport,
            _advancedOrder,
            new CriteriaResolver[](0),
            new Fulfillment[](0)
        );
    }
}
   