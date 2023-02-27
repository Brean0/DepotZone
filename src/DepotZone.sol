// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ZoneInterface } from "seaport/contracts/interfaces/ZoneInterface.sol";

import {
    PausableZoneEventsAndErrors
} from "seaport/contracts/zones/interfaces/PausableZoneEventsAndErrors.sol";

import { SeaportInterface } from "seaport/contracts/interfaces/SeaportInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Execution,
    Fulfillment,
    Order,
    OrderComponents,
    Schema,
    ZoneParameters
} from "seaport/contracts/lib/ConsiderationStructs.sol";

import { PausableZoneInterface } from "seaport/contracts/zones/interfaces/PausableZoneInterface.sol";

import { Depot } from "./Depot.sol";

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone. Note that this zone
 *         cannot execute orders that return native tokens to the fulfiller.
 */
contract DepotZone is
    PausableZoneEventsAndErrors,
    ZoneInterface,
    PausableZoneInterface,
    Depot
{





    /**
     * @notice Cancel an arbitrary number of orders that have agreed to use the
     *         contract as their zone.
     *
     * @param seaport  The Seaport address.
     * @param orders   The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external override returns (bool cancelled) {
        // Call cancel on Seaport and return its boolean value.
        cancelled = seaport.cancel(orders);
    }

    /**
     * @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause(address payee) external {
    }

    /**
     * @notice Assign the given address with the ability to operate the zone.
     *
     * @param operatorToAssign The address to assign as the operator.
     */
    function assignOperator(
        address operatorToAssign
    ) external override {
    }

    /**
     * @notice Execute an arbitrary number of matched orders, each with
     *         an arbitrary number of items for offer and consideration
     *         along with a set of fulfillments allocating offer components
     *         to consideration components. Note that this call will revert if
     *         excess native tokens are returned by Seaport.
     *
     * @param seaport      The Seaport address.
     * @param orders       The orders to match.
     * @param fulfillments An array of elements allocating offer components
     *                     to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        SeaportInterface seaport,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (Execution[] memory executions)
    {
        // Call matchOrders on Seaport and return the sequence of transfers
        // performed as part of matching the given orders.
        executions = seaport.matchOrders{ value: msg.value }(
            orders,
            fulfillments
        );
    }

    /**
     * @notice Execute an arbitrary number of matched advanced orders,
     *         each with an arbitrary number of items for offer and
     *         consideration along with a set of fulfillments allocating
     *         offer components to consideration components. Note that this call
     *         will revert if excess native tokens are returned by Seaport.
     *
     * @param seaport           The Seaport address.
     * @param orders            The orders to match.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        SeaportInterface seaport,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (Execution[] memory executions)
    {  
        // verify that the extra data matches the farm call hash: 
        require(keccak256(orders[0].extraData) == orders[0].parameters.zoneHash, "Invalid extraData");
        //decode the first extraData into a farm bytesCall
        bytes[] memory _farmCall = abi.decode(orders[0].extraData, (bytes[]));
        // put that into a farm function, where the user can do whatever they want
        this.farm(_farmCall);       
        
        // transfers performed as part of matching the given orders.
        executions = seaport.matchAdvancedOrders{ value: msg.value }(
            orders,
            criteriaResolvers,
            fulfillments,
            msg.sender
        );
    }

    /**
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller.
     *
     * @custom:param zoneParameters A struct that provides context about the
     *                              order fulfillment and any supplied
     *                              extraData, as well as all order hashes
     *                              fulfilled in a call to a match or
     *                              fulfillAvailable method.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function validateOrder(
        /**
         * @custom:name zoneParameters
         */
        ZoneParameters calldata zoneData
    ) external pure override returns (bytes4 validOrderMagicValue) {
        require(
            keccak256(zoneData.extraData) == zoneData.zoneHash, 
            "Invalid extraData"
        );
        // Return the selector of isValidOrder as the magic value.
        validOrderMagicValue = ZoneInterface.validateOrder.selector;
    }

    /**
     * @dev Returns the metadata for this zone.
     */
    function getSeaportMetadata()
        external
        pure
        override
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        )
    {
        schemas = new Schema[](1);
        schemas[0].id = 3003;
        schemas[0].metadata = new bytes(0);

        return ("PausableZone", schemas);
    }
}
