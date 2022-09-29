import fs from 'fs';
import {
  attestFromEth,
  createWrappedOnEth,
  getEmitterAddressEth,
  getEmitterAddressSolana,
  getForeignAssetEth,
  parseSequenceFromLogEth,
  redeemOnEth,
  setDefaultWasm,
  transferFromEthNative,
  tryNativeToUint8Array,
} from '@certusone/wormhole-sdk';
import * as ethers from 'ethers';
import fetch from 'node-fetch';
import { promisify } from 'util';

const exec = promisify(require('child_process').exec);
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

let ABI;
try {
  ABI = JSON.parse(fs.readFileSync('./chains/evm/out/Xmint.sol/Xmint.json').toString()).abi;
} catch (e) {
  // fail silenty
  // The only time this fails is when deploy hasn't been called, in which case, this isn't needed
}

/**
 * 1. Deploy on chain core contract
 * @param src The network to deploy
 */
export async function deployCore(src: string) {
  const network = config.local[src];
  const rpc = config.local[src]['rpc'];

  const { stdout, stderr } = await exec(
    `cd src/core && forge build && forge script/Medici.s.sol:DeployCore --rpc-url ${network.rpc}  --private-key ${network.privateKey} --broadcast -vvvv`
  );

  if (stderr) {
    throw new Error(stderr);
  }

  let deploymentAddress: string;
  if (stdout) {
    console.log(stdout);
    deploymentAddress = stdout.split('Deployed to: ')[1].split('\n')[0].trim();
    fs.writeFileSync(
      `./deployinfo/${src}.deploy.json`,
      JSON.stringify(
        {
          address: deploymentAddress,
          tokenAddress: deploymentAddress,
          tokenReceipientAddress: deploymentAddress,
          vaas: [],
        },
        null,
        4
      )
    );
  }
}
