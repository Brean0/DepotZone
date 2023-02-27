// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../interfaces/IBeanstalk.sol";


contract EarnedBeanOracle {
    address constant BEANSTALK = 0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5; 

	function checkEarnedBeanBalance(address account, uint256 amount) public view returns (bool) {
		return IBeanstalk(BEANSTALK).balanceOfEarnedBeans(account) >= amount;
	}

	function checkGrownStalkBalance(address account, uint256 amount) public view returns (bool) {
		return IBeanstalk(BEANSTALK).balanceOfGrownStalk(account) >= amount;
	}

}