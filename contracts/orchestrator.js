import { Command } from 'commander';
import fs from 'fs';

import * as evm from './handlers/evm';
import * as solana from './handlers/solana';

const medici = new Command();
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

medici.name('Medici').description('Cross chain borrowing and lending').version('0.1.0');

xmint
  .command('deploy')
  .description('Deploys on chain code.')
  .argument('<src>', 'the network you want to deply')
  .action(async (src) => {
    if (!config.local[src]) {
      console.error(`ERROR: ${src} not found in xdapp.config.json`);
      return;
    }
    console.log(`Deploying ${src}...`);

    switch (config.networks[src].type) {
      case 'evm':
        await evm.deploy(src);
        break;
      case 'solana':
        await solana.deploy(src);
        break;
    }

    console.log(`Deploy finished!`);
  });

xmint
  .command('register-app')
  .description('Registers the target app and target token with the source on chain app')
  .argument('<src>', 'the network you want to register the app on')
  .argument('<target>', 'the network you want to register')
  .action(async (src, target) => {
    if (!config.local[src]) {
      console.error(`ERROR: ${src} not found in xdapp.config.json`);
      return;
    }
    if (!config.local[target]) {
      console.error(`ERROR: ${target} not found in xdapp.config.json`);
      return;
    }

    let srcHandler;
    switch (config.local[src].type) {
      case 'evm':
        srcHandler = evm;
        break;
      case 'solana':
        xmint
          .command('register-app')
          .description('Registers the target app and target token with the source on chain app')
          .argument('<src>', 'the network you want to register the app on')
          .argument('<target>', 'the network you want to register')
          .action(async (src, target) => {
            if (!config.networks[src]) {
              console.error(`ERROR: ${src} not found in xdapp.config.json`);
              return;
            }
            if (!config.networks[target]) {
              console.error(`ERROR: ${target} not found in xdapp.config.json`);
              return;
            }

            let srcHandler;
            switch (config.networks[src].type) {
              case 'evm':
                srcHandler = evm;
                break;
              case 'solana':
                // srcHandler = solana;
                break;
            }

            console.log(`Registering ${target} app and token onto ${src} network`);
            await srcHandler.registerApp(src, target);
            try {
              console.log(`Attesting ${src} Wrapped Native to ${target}`);
              await srcHandler.attest(src, target, config.networks[src].wrappedNativeAddress);
            } catch (e) {
              console.log('ERROR: ', e);
              console.log('Wrapped Native attestion exists already');
            }

            console.log(
              `${target} contract address was registered on ${src} and ${target} token was attested to ${src}`
            );
          });
        break;
    }

    console.log(`Registering ${target} app and token onto ${src} network`);
    await srcHandler.registerApp(src, target);
    try {
      console.log(`Attesting ${src} Wrapped Native to ${target}`);
      await srcHandler.attest(src, target, config.networks[src].wrappedNativeAddress);
    } catch (e) {
      console.log('ERROR: ', e);
      console.log('Wrapped Native attestion exists already');
    }

    console.log(`${target} contract address was registered on ${src} and ${target} token was attested to ${src}`);
  });
