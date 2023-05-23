pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import './YourToken.sol';

error ErrorTransferingTokensFromTokenContract(address buyer, uint256 amountOfEth, uint256 amountOfTokens);
error WithdrawalFailed(address sender, uint256 amount);
error ErrorTransferingTokensCheckApproval();
error ErrorTransferingEther(address contractAddress, uint256 amount);

contract Vendor is Ownable {
  YourToken public yourToken;

  uint256 public constant tokensPerEth = 100;

  event BuyTokens(address indexed buyer, uint256 amountOfEth, uint256 amountOfTokens);
  event Withdrawal(address indexed sender, uint256 amount);
  event TransferTokens(address indexed seller, uint256 amount);
  event SellTokens(address indexed seller, uint256 amountOfEth, uint256 amountOfTokens);

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  function buyTokens() external payable {
    uint256 amountOfTokens = msg.value * tokensPerEth;

    try yourToken.transfer(msg.sender, amountOfTokens) {
      emit BuyTokens(msg.sender, amountOfTokens, msg.value);
    } catch {
      revert ErrorTransferingTokensFromTokenContract(msg.sender, amountOfTokens, msg.value);
    }
  }

  function withdraw() external onlyOwner {
    uint256 amount = address(this).balance;

    (bool result, ) = msg.sender.call{value: amount}('');
    if (!result) {
      revert WithdrawalFailed(msg.sender, amount);
    }

    emit Withdrawal(msg.sender, amount);
  }

  function sellTokens(uint256 amount) external payable {
    _transferTokensToContract(amount);

    uint256 amountOfEth = amount / 100;

    (bool result, ) = msg.sender.call{value: amountOfEth}('');
    if (!result) {
      revert ErrorTransferingEther(address(this), amountOfEth);
    }

    emit SellTokens(msg.sender, amountOfEth, amount);
  }

  function _transferTokensToContract(uint256 amount) private {
    try yourToken.transferFrom(msg.sender, address(this), amount) {
      emit TransferTokens(msg.sender, amount);
    } catch {
      revert ErrorTransferingTokensCheckApproval();
    }
  }
}
