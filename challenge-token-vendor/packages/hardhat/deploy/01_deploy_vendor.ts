import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployVendor: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  const { ethers } = hre;

  // Lấy contract YourToken (ép kiểu any cho khỏi lỗi TS)
  const yourToken = (await ethers.getContract(
    "YourToken",
    deployer
  )) as any;

  // Deploy Vendor
  const vendorDeployment = await deploy("Vendor", {
    from: deployer,
    args: [yourToken.target ?? yourToken.address],
    log: true,
    autoMine: true,
  });

  const vendorAddress = vendorDeployment.address;

  // Chuyển 1000 token từ deployer sang Vendor
  await yourToken.transfer(
    vendorAddress,
    ethers.parseEther("1000")
  );
};

export default deployVendor;

// Tag để chạy riêng Vendor nếu cần
deployVendor.tags = ["Vendor"];
