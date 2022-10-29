-include .env

.PHONY: dependencies unit-test forge-test integration-test clean all
all: build

.PHONY: clean
clean:
	rm -rf anvil.log node_modules lib out

# check dependencies
.PHONY: dependencies
dependencies: forge-install

forge-install:
	forge install

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Update Dependencies
update:; forge update


### Local single chain and cross-chain testing

.PHONY: forge-test
forge-test: dependencies
	forge test --fork-url ${TESTING_CORE_RPC} -vvv --via-ir

.PHONY: integration-test
integration-test: dependencies build
	bash shell-scripts/run_integration_tests.sh

.PHONY: test
test: forge-test integration-test

### WORLDID INTEGRATION

# Build contracts with worldID and inject the Poseidon library.
build:; forge build && node ./test/scripts/generate-circom-lib.js

# deploy personhood contracts separately for testing worldID
deploy-personhood :; node --no-warnings script/personhood-deploy.js



snapshot :; forge snapshot

slither :; slither ./src

format :; prettier --write src/**/*.sol && prettier --write src/*.sol

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'



deploy-testnet :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --verify

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

deploy-all :; make deploy-${network} contract=MediciPool && make deploy-${network} contract=KeepersCounter && make deploy-${network} contract=PriceFeedConsumer && make deploy-${network} contract=VRFConsumerV2
