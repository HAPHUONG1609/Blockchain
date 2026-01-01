import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat/";
import { DiceGame, RiggedRoll } from "../typechain-types";

const deployRiggedRoll: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const diceGame: DiceGame = await ethers.getContract("DiceGame");
  const diceGameAddress = await diceGame.getAddress();

  // Uncomment to deploy RiggedRoll contract
  //const myFrontendAddress = "0xF2be1c3821bCabcad6242ddBB3f93b63568EA225";

  await deploy("RiggedRoll", {
    from: deployer,
    log: true,
    args: [diceGameAddress],
    autoMine: true,
  });

  // const riggedRoll: RiggedRoll = await ethers.getContract("RiggedRoll", deployer);

  // Please replace the text "Your Address" with your own address.
  // try {
  //   await riggedRoll.transferOwnership("Your Address");
  // } catch (err) {
  //   console.log(err);
  // }
};

export default deployRiggedRoll;

deployRiggedRoll.tags = ["RiggedRoll"];
