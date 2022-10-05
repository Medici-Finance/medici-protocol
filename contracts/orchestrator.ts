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
  .command('register-app')
  .description('Registers the target app and target token with the source on chain app')
  .argument('<src>', 'the network you want to register the app on')
  .argument('<target>', 'the network you want to register')
  .action(async (src, target) => {
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
    await srcHandler.registerApp(src, target);
  });

medici.parse(process.argv);
