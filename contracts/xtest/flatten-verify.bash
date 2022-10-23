
rm src/flattened/fCore.sol
rm src/flattened/fPeriphery.sol


forge flatten src/core/MediciCore.sol >> src/flattened/fCore.sol
forge flatten src/periphery/Periphery.sol >> src/flattened/fPeriphery.sol

# remove spdx comments - **sigh**
grep -v "SPDX" src/flattened/fCore.sol > tmpfile && mv tmpfile src/flattened/fCore.sol
grep -v "SPDX" src/flattened/fPeriphery.sol > tmpfile && mv tmpfile src/flattened/fPeriphery.sol

forge build
