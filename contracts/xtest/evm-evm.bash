npx ts-node orchestrator.ts deploy mumbai core
npx ts-node orchestrator.ts deploy goerli periphery
# npx ts-node orchestrator.ts deploy fuji periphery

# # npx ts-node orchestrator.ts verify goerli periphery

ts-node orchestrator.ts register-app  mumbai goerli core
# ts-node orchestrator.ts register-app  mumbai fuji core

ts-node orchestrator.ts register-app goerli mumbai periphery
# ts-node orchestrator.ts register-app goerli fuji periphery

ts-node orchestrator.ts authenicate-address goerli alice
# ts-node orchestrator.ts get-profile-connections alice

ts-node orchestrator.ts request-loan goerli alice 2000 20 60
ts-node orchestrator.ts submit-vaa goerli mumbai latest

ts-node orchestrator.ts all-loans mumbai

# ts-node orchestrator.ts lend fuji bob 1 600

