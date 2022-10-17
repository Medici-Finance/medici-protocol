forge flatten ../src/core/MediciCore.sol >> ../src/fCore.sol
forge flatten ../src/periphery/Periphery.sol >> ../src/fPeriphery.sol

# remove spdx comments - **sigh**
forge build
