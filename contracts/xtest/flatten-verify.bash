
rm ../src/fCore.sol
rm ../src/fPeriphery.sol

forge flatten ../src/core/MediciCore.sol >> ../src/fCore.sol
forge flatten ../src/periphery/Periphery.sol >> ../src/fPeriphery.sol

grep -v "SPDX" ../src/fCore.sol > tmpfile && mv tmpfile ../src/fCore.sol
grep -v "SPDX" ../src/fPeriphery.sol > tmpfile && mv tmpfile ../src/fPeriphery.sol

# remove spdx comments - **sigh**
forge build
