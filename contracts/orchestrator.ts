import { Command } from 'commander';
import fs from 'fs';

import * as evm from './handlers/evm';
// import * as solana from './handlers/solana';

const medici = new Command();
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

medici.name('Medici').description('Cross chain borrowing and lending').version('0.1.0');

medici
  .command('deploy')
  .description('Deploys on chain code.')
  .argument('<node>', 'core or periphery')
  .argument('<src>', 'the network you want to deply')
  .action(async (src: string, node: string) => {
    if (!config.testnet[src]) {
      console.log(`ERROR: ${src} not found in xdapp.config.json`);
      console.error(`ERROR: ${src} not found in xdapp.config.json`);
      return;
    }
    console.log(`Deploying ${src}...`);

    switch (config.testnet[src].type) {
      case 'evm':
        await evm.deploy(src, node === 'core');
        break;
      case 'solana':
        // await solana.deploy(src);
        break;
    }

    console.log(`Deploy finished!`);
  });

medici
  .command('verify')
  .description("Verifies on the chain's explorer")
  .argument('<chain>', 'the network you want to verify')
  .argument('<node>', 'core or periphery')
  .action(async (chain: string, node: string) => {
    if (!config.testnet[chain]) {
      console.error(`ERROR: ${chain} not found in xdapp.config.json`);
      return;
    }

    let srcHandler;
    switch (config.testnet[chain].type) {
      case 'evm':
        srcHandler = evm;
        break;
      case 'solana':
        break;
    }

    console.log(`Verifying ${node} contracts on ${chain} explorer -- `);
    await srcHandler.verifyContracts(chain, node === 'core');
  });

medici
  .command('register-app')
  .description('Registers the target app and target token with the source on chain app')
  .argument('<src>', 'the network you want to register the app on')
  .argument('<target>', 'the network you want to register')
  .argument('<node>', 'core or periphery')
  .action(async (src: string, target: string, node: string) => {
    if (!config.testnet[src]) {
      console.error(`ERROR: ${src} not found in xdapp.config.json`);
      return;
    }
    if (!config.testnet[target]) {
      console.error(`ERROR: ${target} not found in xdapp.config.json`);
      return;
    }

    let srcHandler;
    switch (config.testnet[src].type) {
      case 'evm':
        srcHandler = evm;
        break;
      case 'solana':
        break;
    }

    console.log(`Registering ${target} app and token onto ${src} network`);
    await srcHandler.registerApp(src, target, node === 'core');
  });

// $ request-loan <amount> <apr> <tenor>
medici
  .command('request-loan')
  .description('Requests a loan on the periphery source chain')
  .argument('<chain>', 'the network you want to request a loan on')
  .argument('<amount>', 'USDC amount to borrow, no decimals')
  .argument('<apr>', 'apr to borrow at, like 22.5%')
  .argument('<tenor>', 'tenor to borrow for in days, like 30')
  .action(async (chain, amount, apr, tenor) => {
    if (!config.testnet[chain]) {
      console.error(`ERROR: ${chain} not found in xdapp.config.json`);
      return;
    }
    try {
      switch (config.testnet[chain].type) {
        case 'evm':
          let amountUint = BigInt(amount) * BigInt(10 ** 6);
          let aprUint = BigInt(parseFloat(apr) * 10 ** 16);
          let tenorUint = BigInt(tenor * 86400);
          console.log(`Requesting loan on ${chain} for ${amountUint} at ${aprUint} for ${tenorUint} seconds`);
          await evm.requestLoan(chain, amountUint, aprUint, tenorUint);
          break;
        case 'solana':
          break;
      }
      console.log(`Emitted VAA on ${chain} network. Submit it using \`submit-vaa\` command on a target network.`);
    } catch (e) {
      console.error(`ERROR: ${e}`);
    }
  });

// $ submit-vaa <source> <target> <vaa#>
medici
  .command('submit-vaa')
  .argument('<source>', 'The network you want to submit the VAA on')
  .argument('<target>', 'The network you want to receive the VAA on')
  .argument(
    '<vaa#>',
    "The index of the VAA in the list of emitted VAAs that you want to submit. Use 'latest' to submit the latest VAA"
  )
  .action(async (src, target, idx) => {
    if (!config.testnet[src]) {
      console.error(`ERROR: ${src} not found in xdapp.config.json`);
      return;
    }
    if (!config.testnet[target]) {
      console.error(`ERROR: ${target} not found in xdapp.config.json`);
      return;
    }

    try {
      switch (config.testnet[src].type) {
        case 'evm':
          await evm.submitVaa(src, target, idx);
          break;
        case 'solana':
          // await solana.submitVaa(src, target, idx);
          break;
      }

      console.log(`Submitted VAA #${idx} from ${src} to chain ${target}`);
    } catch (e) {
      console.error(`ERROR: ${e}`);
    }
  });

// $ all-loans
medici
  .command('all-loans')
  .argument('<core>', 'The core network holding the global state')
  .action(async (core) => {
    if (!config.testnet[core]) {
      console.error(`ERROR: ${core} not found in xdapp.config.json`);
      return;
    }

    let allLoans;

    try {
      switch (config.testnet[core].type) {
        case 'evm':
          allLoans = await evm.getOpenLoans(core);
          break;
        case 'solana':
          // await solana.submitVaa(src, target, idx);
          break;
      }

      console.log(`Reading open loans state from ${core}: ${JSON.stringify(allLoans)}`);
    } catch (e) {
      console.error(`ERROR: ${e}`);
    }
  });

medici.parse(process.argv);
