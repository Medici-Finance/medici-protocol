-include .env

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install smartcontractkit/chainlink-brownie-contracts && forge install rari-capital/solmate && forge install foundry-rs/forge-std

# Update Dependencies
update:; forge update

# Build contracts and inject the Poseidon library.
build:; forge build && node ./test/scripts/generate-circom-lib.js

test :; forge test -vv

snapshot :; forge snapshot

slither :; slither ./src

format :; prettier --write src/**/*.sol && prettier --write src/*.sol

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'

build:; @forge build && node ./test/scripts/generate-circom-lib.js

deploy-personhood :; node --no-warnings script/personhood-deploy.js

# use the "@" to hide the command from your shell
deploy-rinkeby :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${RINKEBY_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv

verify-contract :; forge verify-contract --chain-id 80001 --num-of-optimizations 10000 --constructor-args \
    $(cast abi-encode "constructor(ERC20,address,address, uint256,uint256)" "HOW?" "FUSD" 90 200000000000000000) \
    --compiler-version v0.8.15+commit.e14f2714 <the_contract_address> src/MyToken.sol:MyToken ${POLYSCAN_API_KEY}

deploy-testnet :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

deploy-all :; make deploy-${network} contract=MediciPool && make deploy-${network} contract=KeepersCounter && make deploy-${network} contract=PriceFeedConsumer && make deploy-${network} contract=VRFConsumerV2

deploy-export :; make deploy-${network} contract=${contract} && cp ./out/${contract}.sol/${contract}.json ../frontend/src/sdk/abi/${contract}.abi.json

deploy-export-all :; make deploy-all network=testnet
