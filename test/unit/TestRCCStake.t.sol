//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {DeployRCCStake} from "../../script/DeployRCCStake.s.sol";
import {RCCStake} from "../../src/RCCStake.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RCCStakeToken} from "../../src/RCCStakeToken.sol";

contract TestRCCStake is Test {
    RCCStake rccStake;
    address USER = makeAddr("user");
    address mostRecentlyDeployed;

    function setUp() external {
        DeployRCCStake deployer = new DeployRCCStake();
        rccStake = deployer.run();
        mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "RCCStakeToken",
            block.chainid
        );

        address rccStakeToken = mostRecentlyDeployed;
        rccStake.initialize(
            IERC20(rccStakeToken),
            block.number,
            block.number + 100,
            4
        );
    }

    function testAdminRoleIsRight() public view {
        assertEq(rccStake.ADMIN_ROLE(), keccak256("admin_role"));
    }

    function testUpgradeRoleIsRight() public view {
        assertEq(rccStake.UPGRADE_ROLE(), keccak256("upgrade_role"));
    }

    function testPauseWithdrawByNormalRole() public {
        vm.prank(USER);
        vm.expectRevert();
        rccStake.pauseWithdraw();
    }

    function testPauseWithdrawByAdminRole() public {
        //console.log(address(this));
        vm.prank(address(this));

        rccStake.pauseWithdraw();
        assertEq(rccStake.withdrawPaused(), true);
    }

    // 需要补充测试 emit PauseWithdraw();

    function testUnpauseWithdrawByNormalRole() public {
        vm.prank(USER);
        vm.expectRevert();
        rccStake.unpauseWithdraw();
    }

    function testUnpauseWithdrawByAdminRole() public {
        vm.prank(address(this));
        rccStake.pauseWithdraw();

        vm.prank(address(this));
        rccStake.unpauseWithdraw();
        assertEq(rccStake.withdrawPaused(), false);
    }

    // 需要补充测试 emit UnpauseWithdraw();

    function testPauseClaimByNormalRole() public {
        vm.prank(USER);
        vm.expectRevert();
        rccStake.pauseClaim();
    }

    function testPauseClaimByAdminRole() public {
        vm.prank(address(this));
        rccStake.pauseClaim();
        assertEq(rccStake.claimPaused(), true);
    }

    // 需要补充测试 emit PauseClaim();

    function testUnpauseClaimByNormalRole() public {
        vm.prank(USER);
        vm.expectRevert();
        rccStake.unpauseClaim();
    }

    function testUnpauseClaimByAdminRole() public {
        vm.prank(address(this));
        rccStake.pauseClaim();

        vm.prank(address(this));
        rccStake.unpauseClaim();
        assertEq(rccStake.claimPaused(), false);
    }

    // 需要补充测试 emit UnpauseClaim();

    function testSetStartBlockMoreThanEndBlock() public {
        vm.prank(address(this));
        vm.expectRevert();
        rccStake.setStartBlock(block.number + 101);
    }

    function testSetStartBlockInRange() public {
        vm.prank(address(this));
        rccStake.setStartBlock(10);
        assertEq(rccStake.startBlock(), 10);
        console.log(block.number);
    }

    // 需要补充测试 emit SetStartBlock(_startBlock);
    event SetStartBlock(uint256 indexed startBlock);

    function testEventSetStartBlock() public {
        vm.expectEmit(true, false, false, true);
        emit SetStartBlock(block.number + 20);

        rccStake.setStartBlock(block.number + 20);
    }

    function testSetEndBlockLessThanStartBlock() public {
        vm.prank(address(this));
        vm.expectRevert();
        rccStake.setEndBlock(block.number - 1);
    }

    // 需要补充测试 emit SetEndBlock(_endBlock);
    event SetEndBlock(uint256 indexed endBlock);

    function testEventSetEndBlock() public {
        vm.expectEmit(true, false, false, true);
        emit SetEndBlock(block.number + 150);

        rccStake.setEndBlock(block.number + 150);
    }

    function testSetRCCPerBlock() public {
        vm.prank(address(this));
        rccStake.setRCCPerBlock(10);

        assertEq(rccStake.RCCPerBlock(), 10);
    }

    // function testAddPoolWithNativeCurrency() public {
    //     vm.prank(address(this));

    //     rccStake.addPool();
    // }

    function testUpdatePoolInfo() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        rccStake.updatePool(0, 10, 7);

        (uint256 minDepositAmount, uint256 unstakeLockedBlocks) = rccStake
            .getPoolInfo(0);
        assertEq(minDepositAmount, 10);
        assertEq(unstakeLockedBlocks, 7);
    }

    // 需要测试 emit UpdatePoolInfo(_pid, _minDepositAmount, _unstakeLockedBlocks);
    event UpdatePoolInfo(
        uint256 indexed poolId,
        uint256 indexed minDepositAmount,
        uint256 indexed unstakeLockedBlocks
    );

    function testEventUpdatePoolInfo() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        vm.expectEmit(true, true, true, true);
        emit UpdatePoolInfo(0, 10, 7);
        rccStake.updatePool(0, 10, 7);
    }

    function testSetPoolWeight() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        rccStake.setPoolWeight(0, 35, true);

        assertEq(rccStake.totalPoolWeight(), 35);
        assert(rccStake.getPoolWeight(0) == 35);
    }

    // 需要测试 emit SetPoolWeight();
    event SetPoolWeight(
        uint256 indexed poolId,
        uint256 indexed poolWeight,
        uint256 totalPoolWeight
    );

    function testEventSetPoolWeight() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        vm.expectEmit(true, true, false, true);
        emit SetPoolWeight(0, 35, 35);
        rccStake.setPoolWeight(0, 35, true);
    }

    function testPoolLength() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        assertEq(rccStake.poolLength(), 1);
    }

    function testGetMultiplierInWrongRange() public {
        vm.expectRevert();
        rccStake.getMultiplier(block.number + 30, block.number + 20);
    }

    function testGetMultiplier() public view {
        uint256 multiplier = rccStake.getMultiplier(
            block.number,
            block.number + 20
        );

        assertEq(multiplier, 20 * rccStake.RCCPerBlock());
    }

    function testPendingRCCByBlockNumber() public {}

    function testDepositNativeCurrencyPoolSTTokenAddress() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(USER);
        vm.deal(USER, 20 ether);

        assertEq(rccStake.getPoolSTTokenAddress(0), address(0x0));
    }

    function testDepositNativeCurrencyLessThanMinDepositAmount() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(USER);
        vm.deal(USER, 20 ether);

        vm.expectRevert();
        rccStake.depositnativeCurrency{value: 3}();
    }

    function testDepositWithWrongPoolId() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        rccStake.addPool(mostRecentlyDeployed, 50, 20, 5, true);

        vm.expectRevert();
        rccStake.deposit(0, 30);
    }

    function testDepositLessThanMinDepositAmount() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(address(this));
        rccStake.addPool(mostRecentlyDeployed, 50, 20, 5, true);

        (uint256 minDespoit, ) = rccStake.getPoolInfo(1);
        console.log("minDespoit ", minDespoit);

        vm.prank(USER);
        vm.expectRevert();
        rccStake.deposit(1, 10);
    }

    function testUnstakeRevertMoreThanAmount() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        rccStake.depositnativeCurrency{value: 2 ether}();

        vm.roll(block.number + 50);
        vm.prank(msg.sender);
        vm.expectRevert();
        rccStake.unstake(0, 3 ether);
    }

    function testUnstakeIsRight() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        rccStake.depositnativeCurrency{value: 2 ether}();

        vm.roll(block.number + 30);
        vm.prank(msg.sender);
        rccStake.unstake(0, 1 ether);

        uint256 amount = rccStake.getPoolSTAmount(0);
        assertEq(amount, 1 ether);

        vm.prank(msg.sender);
        (uint256 _amount, uint256 unlockBlocks) = rccStake
            .getUserRequestByIndex(0, 0);

        assertEq(_amount, 1 ether);
        assertEq(unlockBlocks, rccStake.startBlock() + 30 + 5);
    }

    // 需要测试emit RequestUnstake(msg.sender, _pid, _amount);
    event RequestUnstake(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    function testEventRequestUnstake() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        rccStake.depositnativeCurrency{value: 2 ether}();

        vm.expectEmit(true, true, false, true);
        emit RequestUnstake(msg.sender, 0, 1 ether);

        vm.roll(block.number + 30);
        vm.prank(msg.sender);
        rccStake.unstake(0, 1 ether);
    }

    function testWithdraw() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 5 ether);
        rccStake.depositnativeCurrency{value: 5 ether}();

        vm.roll(block.number + 30);
        vm.prank(msg.sender);
        rccStake.unstake(0, 2 ether);

        uint256 startBal = msg.sender.balance;
        console.log("start balance ", startBal);

        vm.roll(block.number + 10);
        vm.prank(msg.sender);
        rccStake.withdraw(0);
        uint256 endBal = msg.sender.balance;
        console.log("end balance ", endBal);

        assertEq(startBal + 2 ether, endBal);
    }

    function testWithdrawNotExceedUnstakeLockedBlocks() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 5 ether);
        rccStake.depositnativeCurrency{value: 5 ether}();

        vm.roll(block.number + 30);
        vm.prank(msg.sender);
        rccStake.unstake(0, 2 ether);
        uint256 startBal = msg.sender.balance;

        vm.roll(block.number + 3);
        vm.prank(msg.sender);
        rccStake.withdraw(0);
        uint256 endBal = msg.sender.balance;

        assertEq(startBal, endBal);
    }

    // 需要测试 emit Withdraw(msg.sender, _pid, pendingWithdraw_, block.number);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 indexed blockNumber
    );

    function testEventWithdraw() public {
        vm.prank(address(this));
        rccStake.addPool(address(0x0), 20, 5, 5, true);

        vm.prank(msg.sender);
        vm.deal(msg.sender, 5 ether);
        rccStake.depositnativeCurrency{value: 5 ether}();

        vm.roll(block.number + 30);
        vm.prank(msg.sender);
        rccStake.unstake(0, 2 ether);

        vm.roll(block.number + 10);
        vm.prank(msg.sender);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(msg.sender, 0, 2 ether, block.number);

        rccStake.withdraw(0);
    }

    // function testClaim() public {
    //     console.log("start balance  ", address(this).balance);
    //     vm.prank(address(this));
    //     rccStake.addPool(address(0x0), 20, 5, 5, true);

    //     // vm.prank(msg.sender);
    //     // vm.deal(msg.sender, 5 ether);
    //     // rccStake.depositnativeCurrency{value: 5 ether}();

    //     // vm.roll(block.number + 30);
    //     // //vm.prank(msg.sender);
    //     // rccStake.claim(0);
    //     // //uint256 startBal = msg.sender.balance;
    //     // console.log("reward ", msg.sender.balance);

    //     vm.prank(USER);
    //     vm.deal(USER, 5 ether);
    //     rccStake.depositnativeCurrency{value: 5 ether}();

    //     vm.roll(block.number + 30);
    //     vm.prank(USER);
    //     rccStake.claim(0);
    //     //uint256 startBal = msg.sender.balance;
    //     console.log("reward ", USER.balance);
    // }
}
